import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'domain.dart';
import 'firebase_service.dart';
import 'firebase_accounts.dart';
import 'firebase_plans.dart';
import 'local_ai.dart';
import 'discovery_service.dart';
import 'notifications.dart';
import 'social_service.dart';

part 'store_features.dart';
part 'routing_store.dart';
part 'social_store.dart';

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
    try {
      final savedHistory = preferences.getString('meet.flutter.history');
      if (savedHistory != null) {
        history.addAll(List<Json>.from(jsonDecode(savedHistory) as List));
      }
    } catch (_) {
      /* Old history must not block the planner. */
    }
    localAI.addListener(changed);
    notifications.addListener(changed);
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
  late final LocalAI localAI = LocalAI();
  late final DiscoveryService discovery = DiscoveryService(preferences);
  late final NotificationService notifications = NotificationService(
    cloud,
    preferences,
  );
  bool offline = false, liveFromCache = false;
  StreamSubscription<List<ConnectivityResult>>? _network;
  StreamSubscription<QuerySnapshot<Json>>? _liveList;
  StreamSubscription<DocumentSnapshot<Json>>? _profile;
  final Map<String, StreamSubscription<QuerySnapshot<Json>>> _eventFeeds = {};
  final List<Json> activityFeed = [];
  String? serviceNotice;
  String? pendingFriendLink, pendingRoomId;
  bool routingBusy = false;
  double routingProgress = 0;
  int _routingGeneration = 0;
  final List<Json> friends = [], planInvites = [], history = [];
  final Set<String> _archiving = {};
  StreamSubscription<QuerySnapshot<Json>>? _friendsFeed,
      _planInvitesFeed,
      _historyFeed;
  void changed() => notifyListeners();
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
  String? streamError, reopenedNotice;
  void setBusy(bool value) {
    busy = value;
    notifyListeners();
  }

  Planner get planner => Planner(data, room: room);
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
    reopenedNotice = null;
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
    reopenedNotice = null;
    explanations = [];
    selected = '';
    if (!value.local) {
      await cloud.connect();
      _subscription = cloud
          .watchRoom(value.id)
          .listen(
            (fresh) {
              final previous = room;
              if (previous?.id != fresh.id) return;
              if (previous!.proposal != null && fresh.proposal == null) {
                reopenedNotice = _reopened(
                  fresh.ownerId != previous.ownerId
                      ? 'The host changed'
                      : fresh.title != previous.title ||
                            fresh.date != previous.date
                      ? 'The plan details changed'
                      : fresh.members.length > previous.members.length
                      ? 'Someone joined'
                      : fresh.members.length < previous.members.length
                      ? 'Someone left the plan'
                      : fresh.options.length != previous.options.length
                      ? 'The activity options changed'
                      : 'The group’s shared details changed',
                );
              } else if (fresh.proposal != null) {
                reopenedNotice = null;
              }
              room = fresh;
              if (fresh.status == 'confirmed') {
                unawaited(rememberCurrentPlan().catchError((Object _) {}));
              }
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
    final now = DateTime.now();
    if (parsed.isBefore(DateTime(now.year, now.month, now.day))) {
      throw const FormatException('Choose today or a later date.');
    }
    name = displayName;
    await preferences.setString('meet.flutter.name', name);
    if (live) {
      final id = await cloud.createRoom(title, date, name);
      await preferences.setBool('meet.flutter.live', true);
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
    await preferences.setBool('meet.flutter.live', true);
    await refreshLive();
    await openRoom(liveRooms.firstWhere((r) => r.id == id));
  }

  Future<void> refreshLive() async {
    // Fetch before clearing so overlapping refreshes can't duplicate plans.
    final fresh = await cloud.rooms();
    liveRooms
      ..clear()
      ..addAll(fresh);
    await _watchLivePlans();
    openPendingRoom();
    notifyListeners();
  }

  /// Reloads live plans after a relaunch, without creating a guest identity
  /// for someone who has never used a live plan on this device.
  Future<void> restoreLive() async {
    if (!cloud.configured || preferences.getBool('meet.flutter.live') != true) {
      return;
    }
    try {
      await refreshLive();
    } catch (_) {
      /* Offline launches keep local plans; Refresh live plans can retry. */
    }
  }

  Future<String> invitationLink() async {
    final token = await cloud.invitationFor(room!);
    return Uri.parse(cloud.publicUrl)
        .replace(queryParameters: {'invite': token})
        .toString();
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
        _reset(current, '${person.name} updated their preferences');
        explanations = [];
        await persist();
      } else {
        await cloud.shareCard(current, card, name);
      }
    }
    defaultCard = card;
    await preferences.setString('meet.flutter.card', jsonEncode(card.toJson()));
    if (cloud.hasAccount) await cloud.saveProfile(name, card);
    notifyListeners();
  }

  void _reset(PlanRoom current, String reason) {
    if (current.proposal != null) reopenedNotice = _reopened(reason);
    current.reset();
  }

  Future<void> addSamplePerson() async {
    final current = room!;
    if (!current.local || current.members.length >= cloud.maxGroupSize) {
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
    _reset(current, '${seed.name} joined');
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
      _reset(current, 'A new idea was added');
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
    if (current.status == 'confirmed') {
      throw StateError('This plan is already confirmed.');
    }
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
      reopenedNotice = null;
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
    if (current.proposal?.stops.isNotEmpty == true) {
      final activities = proposalActivities(
        current,
        planner.catalogFor(current),
      );
      final itinerary = planner.itinerary(activities, current.members);
      if (!itinerary.eligible ||
          itinerary.stops.length != current.proposal!.stops.length ||
          !itinerary.stops.indexed.every(
            (entry) => mapEquals(entry.$2, current.proposal!.stops[entry.$1]),
          )) {
        throw StateError(
          'The itinerary changed or no longer fits. Review a new proposal before confirming.',
        );
      }
    }
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
      await rememberCurrentPlan();
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

  Future<PreferenceCard> extractLocal(String note, PreferenceCard base) async {
    final (card, receipt) = await localAI.draft(note, base, data);
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
    if (cloud.hasAccount) await cloud.saveProfile(name, defaultCard!);
    notifyListeners();
  }

  Future<void> resetLocal() async {
    // Shared live plans survive a local reset, so keep reloading them.
    final live = preferences.getBool('meet.flutter.live') ?? false;
    for (final key
        in preferences
            .getKeys()
            .where(
              (k) =>
                  k.startsWith('meet.flutter.') ||
                  k.startsWith('meet.route.') ||
                  k.startsWith('meet.discovery.'),
            )
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
    history.removeWhere((entry) => entry['cloud'] != true);
    explanations = [];
    reopenedNotice = null;
    await preferences.setString('meet.flutter.identity', identity);
    if (live) await preferences.setBool('meet.flutter.live', true);
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
    _network?.cancel();
    _liveList?.cancel();
    _profile?.cancel();
    _friendsFeed?.cancel();
    _planInvitesFeed?.cancel();
    _historyFeed?.cancel();
    for (final feed in _eventFeeds.values) {
      feed.cancel();
    }
    localAI.removeListener(changed);
    notifications.removeListener(changed);
    notifications.dispose();
    unawaited(localAI.cancel());
    super.dispose();
  }
}

String _reopened(String reason) =>
    '$reason, so the decision reopened. Earlier votes no longer count.';

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'email-already-in-use' => 'That email already has an account. Sign in instead, or use a different email to preserve this guest’s plans.',
      'invalid-email' => 'Enter a valid email address.',
      'weak-password' =>
        'Choose a stronger password with at least six characters.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => 'The email or password was not accepted.',
      'operation-not-allowed' => 'Email sign-in has not been enabled for this build’s Firebase project yet.',
      'too-many-requests' =>
        'Too many attempts. Wait a little before trying again.',
      'requires-recent-login' =>
        'Sign in again before changing or deleting this account.',
      _ => 'Sign-in didn’t go through. Check your connection and try again.',
    };
  }
  if (error is CloudAIException) return error.message;
  if (error is FormatException) return error.message;
  if (error is StateError) return error.message.toString();
  // SDK errors can contain internal identifiers; keep them out of product messages.
  return 'That didn’t go through. Check your connection and try again.';
}
