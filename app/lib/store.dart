import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain.dart';
import 'firebase_service.dart';

class MeetStore extends ChangeNotifier {
  MeetStore(this.data, this.preferences, this.cloud) {
    identity = preferences.getString('meet.flutter.identity') ?? randomId(12);
    name = preferences.getString('meet.flutter.name') ?? 'You';
    preferences.setString('meet.flutter.identity', identity);
    final saved = preferences.getString('meet.flutter.rooms');
    try {
      if (saved != null) {
        localRooms.addAll(
          (jsonDecode(saved) as List).map((r) => PlanRoom.fromJson(r as Json)),
        );
      }
    } catch (_) {
      loadNotice = 'Some saved plans could not be read. Your sample group is still available.';
    }
    if (!localRooms.any((r) => r.id == 'sample-toronto')) {
      localRooms.add(_sample());
    }
    try {
      final saved = preferences.getString('meet.flutter.card');
      if (saved != null) {
        defaultCard = PreferenceCard.fromJson(jsonDecode(saved) as Json)
          ..validate(data);
      }
    } catch (_) {
      /* Invalid saved defaults are ignored. */
    }
    defaultCard ??= data.defaultCard;
  }
  static Future<MeetStore> load() async {
    final data = Experience.fromJson(
      jsonDecode(await rootBundle.loadString('assets/shared/experience.json'))
          as Json,
    );
    return MeetStore(
      data,
      await SharedPreferences.getInstance(),
      await FirebaseService.load(),
    );
  }

  final Experience data;
  final SharedPreferences preferences;
  final FirebaseService cloud;
  late String identity, name;
  String? loadNotice;
  PreferenceCard? defaultCard;
  final List<PlanRoom> localRooms = [], liveRooms = [];
  final List<AIReceipt> receipts = [];
  List<PlanExplanation> explanations = [];
  int? explanationRevision;
  PlanRoom? room;
  String tab = 'discover', persona = 'alex', selected = '';
  bool busy = false;
  StreamSubscription<PlanRoom>? _subscription;
  String? streamError;
  void setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Planner get planner => Planner(data);
  String get myId => room?.local == true
      ? (room!.members.any((m) => m.id == persona) ? persona : identity)
      : (cloud.connected ? cloud.uid : identity);
  Person? get me => room?.members.where((m) => m.id == myId).firstOrNull;
  bool get isHost => room?.ownerId == myId;
  List<RankedPlan> get ranked => room == null
      ? []
      : planner.rank(room!.members, planner.catalogFor(room!));
  RankedPlan? get chosen =>
      ranked.where((r) => r.candidate.id == selected).firstOrNull ??
      ranked.firstOrNull;
  PlanRoom _sample() => PlanRoom(
    id: 'sample-toronto',
    title: 'Saturday, sorted.',
    date: nextSaturday(),
    ownerId: 'alex',
    members: data.samplePeople.map((p) => Person.fromJson(p.toJson())).toList(),
  );
  void navigate(String value) {
    tab = value;
    room = null;
    streamError = null;
    _subscription?.cancel();
    _subscription = null;
    explanations = [];
    notifyListeners();
  }

  Future<void> openRoom(PlanRoom value) async {
    await _subscription?.cancel();
    if (value.local && !value.members.any((m) => m.id == persona)) {
      persona = value.ownerId;
    }
    room = value;
    tab = 'plans';
    streamError = null;
    explanations = [];
    selected = '';
    if (!value.local) {
      await cloud.connect();
      _subscription = cloud
          .watchRoom(value.id)
          .listen(
            (fresh) {
              if (room?.id != fresh.id) return;
              room = fresh;
              streamError = null;
              if (explanationRevision != fresh.revision) explanations = [];
              notifyListeners();
            },
            onError: (Object error) {
              streamError = friendlyError(error);
              notifyListeners();
            },
          );
    }
    notifyListeners();
  }

  Future<void> openSample([String asPerson = 'alex']) async {
    persona = asPerson;
    await openRoom(localRooms.firstWhere((r) => r.id == 'sample-toronto'));
  }

  void select(String id) {
    selected = id;
    notifyListeners();
  }

  void switchPerson(String id) {
    if (room?.local == true && room!.members.any((m) => m.id == id)) {
      persona = id;
      notifyListeners();
    }
  }

  Future<void> create(
    String title,
    String date,
    String displayName, {
    required bool live,
  }) async {
    title = title.trim();
    displayName = displayName.trim();
    if (title.isEmpty ||
        title.length > 70 ||
        displayName.isEmpty ||
        displayName.length > 30) {
      throw const FormatException('Add a plan title and your first name.');
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null || isoDate(parsed) != date) {
      throw const FormatException('Choose a valid date.');
    }
    name = displayName;
    await preferences.setString('meet.flutter.name', name);
    if (live) {
      final id = await cloud.createRoom(title, date, name);
      await refreshLive();
      await openRoom(liveRooms.firstWhere((r) => r.id == id));
    } else {
      final value = PlanRoom(
        id: randomId(10),
        title: title,
        date: date,
        ownerId: identity,
        members: [Person(id: identity, name: name)],
      );
      localRooms.insert(0, value);
      await persist();
      await openRoom(value);
    }
  }

  Future<void> join(String invitation, String displayName) async {
    displayName = displayName.trim();
    if (displayName.isEmpty || displayName.length > 30) {
      throw const FormatException('Add your first name.');
    }
    final uri = Uri.tryParse(invitation.trim());
    final token = uri?.queryParameters['invite'] ?? invitation.trim();
    final id = await cloud.join(token, displayName);
    name = displayName;
    await preferences.setString('meet.flutter.name', name);
    await refreshLive();
    await openRoom(liveRooms.firstWhere((r) => r.id == id));
  }

  Future<void> refreshLive() async {
    liveRooms
      ..clear()
      ..addAll(await cloud.rooms());
    notifyListeners();
  }

  Future<void> shareCard(PreferenceCard card) async {
    card.validate(data);
    final current = room;
    if (current != null) {
      if (current.local) {
        final person = me;
        if (person == null) {
          throw StateError('Join this plan before sharing preferences.');
        }
        person.card = card;
        current.reset();
        explanations = [];
        await persist();
      } else {
        await cloud.shareCard(current, card, name);
      }
    }
    defaultCard = card;
    await preferences.setString('meet.flutter.card', jsonEncode(card.toJson()));
    notifyListeners();
  }

  Future<void> addSamplePerson() async {
    final current = room!;
    if (!current.local || current.members.length >= 8) {
      throw StateError(
        'Sample participants are available only in local plans with space.',
      );
    }
    final seed = data.samplePeople
        .where((p) => !current.members.any((m) => m.id == p.id))
        .firstOrNull;
    if (seed == null) {
      throw StateError(
        'All sample people are already here. Invite real people through a live plan.',
      );
    }
    current.members.add(Person.fromJson(seed.toJson()));
    current.reset();
    await persist();
    notifyListeners();
  }

  Future<void> addOption(Json option) async {
    final current = room!;
    if (!isHost) throw StateError('Only the host can add an activity.');
    data.validateOption(option);
    if (current.options.length >= 12) {
      throw StateError('This plan already has twelve activities.');
    }
    if (current.local) {
      final id = List.generate(
        12,
        (i) => 'option-${(i + 1).toString().padLeft(2, '0')}',
      ).firstWhere((id) => !current.options.any((o) => o['id'] == id));
      current.options.add({'id': id, ...option});
      current.reset();
      explanations = [];
      await persist();
      notifyListeners();
    } else {
      await cloud.addOption(current, option);
    }
  }

  Future<void> propose(RankedPlan rank) async {
    final current = room!;
    if (!isHost) throw StateError('Only the host can propose a plan.');
    final fresh = ranked
        .where((p) => p.candidate.id == rank.candidate.id)
        .firstOrNull;
    if (current.members.length < 2 || fresh == null) {
      throw StateError(
        'Everyone needs to share preferences before you propose an eligible plan.',
      );
    }
    if (current.local) {
      current.revision++;
      current.proposal = Proposal(
        fresh.candidate.id,
        fresh.start!,
        current.revision,
      );
      current.votes = {};
      current.status = 'voting';
      await persist();
      notifyListeners();
    } else {
      await cloud.propose(current, fresh);
    }
  }

  Future<void> vote(String choice) async {
    final current = room!;
    if (current.status != 'voting' ||
        current.proposal == null ||
        me?.card == null ||
        !['yes', 'maybe', 'no'].contains(choice)) {
      throw StateError('Choose an active proposal first.');
    }
    if (current.local) {
      current.votes[myId] = PlanVote(
        choice,
        current.proposal!.candidateId,
        current.proposal!.revision,
      );
      await persist();
      notifyListeners();
    } else {
      await cloud.vote(current, choice);
    }
  }

  Future<void> confirm() async {
    final current = room!;
    if (!isHost ||
        !current.canConfirm ||
        !ranked.any((p) => p.candidate.id == current.proposal!.candidateId)) {
      throw StateError(
        'Everyone must accept the current eligible proposal first.',
      );
    }
    if (current.local) {
      current.status = 'confirmed';
      await persist();
      notifyListeners();
    } else {
      await cloud.confirm(current);
    }
  }

  Future<PreferenceCard> extract(String note, PreferenceCard base) async {
    final (card, receipt) = await cloud.extractNote(note, base, data);
    receipts.add(receipt);
    notifyListeners();
    return card;
  }

  Future<void> explain() async {
    final current = room!, revision = current.revision;
    final (result, receipt) = await cloud.explain(current, ranked);
    receipts.add(receipt);
    if (room?.id != current.id || room?.revision != revision) {
      throw StateError(
        'The group changed. Request an explanation for the new shortlist.',
      );
    }
    explanations = result;
    explanationRevision = revision;
    notifyListeners();
  }

  Future<void> feedback(Activity activity, bool more) async {
    final base = defaultCard!, tags = base.interests.toSet();
    if (more) {
      tags.addAll(activity.tags);
    } else {
      tags.removeAll(activity.tags);
    }
    if (tags.isEmpty) tags.add('outdoors');
    defaultCard = base.copyWith(interests: tags.take(6).toList());
    await preferences.setString(
      'meet.flutter.card',
      jsonEncode(defaultCard!.toJson()),
    );
    notifyListeners();
  }

  Future<void> resetLocal() async {
    for (final key
        in preferences
            .getKeys()
            .where((k) => k.startsWith('meet.flutter.'))
            .toList()) {
      await preferences.remove(key);
    }
    localRooms
      ..clear()
      ..add(_sample());
    defaultCard = data.defaultCard;
    room = null;
    tab = 'discover';
    receipts.clear();
    explanations = [];
    await preferences.setString('meet.flutter.identity', identity);
    await persist();
    notifyListeners();
  }

  Future<void> persist() async {
    await preferences.setString(
      'meet.flutter.rooms',
      jsonEncode(localRooms.map((r) => r.toJson()).toList()),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

String friendlyError(Object error) {
  if (error is CloudAIException) return error.message;
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  // SDK errors can contain internal identifiers; keep them out of product messages.
  return 'That didn’t go through. Check your connection and try again.';
}
