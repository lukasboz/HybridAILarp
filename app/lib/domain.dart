import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

typedef Json = Map<String, dynamic>;

const cardKeys = {
  'areaId',
  'maxSpend',
  'maxTravel',
  'mode',
  'interests',
  'earliest',
  'latest',
  'quiet',
  'indoors',
  'stepFree',
};

class PreferenceCard {
  const PreferenceCard({
    required this.areaId,
    required this.maxSpend,
    required this.maxTravel,
    required this.mode,
    required this.interests,
    required this.earliest,
    required this.latest,
    required this.quiet,
    required this.indoors,
    required this.stepFree,
  });

  factory PreferenceCard.fromJson(Json json) {
    if (json.keys.toSet().difference(cardKeys).isNotEmpty ||
        !cardKeys.every(json.containsKey)) {
      throw const FormatException(
        'The card contains missing or unapproved fields.',
      );
    }
    return PreferenceCard(
      areaId: json['areaId'] as String,
      maxSpend: json['maxSpend'] as int,
      maxTravel: json['maxTravel'] as int,
      mode: json['mode'] as String,
      interests: List<String>.from(json['interests'] as List),
      earliest: json['earliest'] as int,
      latest: json['latest'] as int,
      quiet: json['quiet'] as bool,
      indoors: json['indoors'] as bool,
      stepFree: json['stepFree'] as bool,
    );
  }

  final String areaId, mode;
  final int maxSpend, maxTravel, earliest, latest;
  final List<String> interests;
  final bool quiet, indoors, stepFree;

  Json toJson() => {
    'areaId': areaId,
    'maxSpend': maxSpend,
    'maxTravel': maxTravel,
    'mode': mode,
    'interests': interests,
    'earliest': earliest,
    'latest': latest,
    'quiet': quiet,
    'indoors': indoors,
    'stepFree': stepFree,
  };

  PreferenceCard copyWith({
    String? areaId,
    String? mode,
    int? maxSpend,
    int? maxTravel,
    int? earliest,
    int? latest,
    List<String>? interests,
    bool? quiet,
    bool? indoors,
    bool? stepFree,
  }) => PreferenceCard(
    areaId: areaId ?? this.areaId,
    mode: mode ?? this.mode,
    maxSpend: maxSpend ?? this.maxSpend,
    maxTravel: maxTravel ?? this.maxTravel,
    earliest: earliest ?? this.earliest,
    latest: latest ?? this.latest,
    interests: interests ?? this.interests,
    quiet: quiet ?? this.quiet,
    indoors: indoors ?? this.indoors,
    stepFree: stepFree ?? this.stepFree,
  );

  void validate(Experience data) {
    if (!data.areas.any((a) => a['id'] == areaId)) {
      throw const FormatException('Choose a neighbourhood.');
    }
    if (maxSpend < 0 ||
        maxSpend > 200 ||
        maxTravel < 5 ||
        maxTravel > 120 ||
        earliest < 360 ||
        earliest > 1380 ||
        latest < 390 ||
        latest > 1440 ||
        latest - earliest < 90) {
      throw const FormatException(
        'Check your budget, travel limit and available time. Allow at least 90 minutes.',
      );
    }
    if (!{'transit', 'walk', 'bike'}.contains(mode) ||
        interests.isEmpty ||
        interests.length > 6 ||
        interests.toSet().length != interests.length ||
        interests.any((id) => !data.interests.any((i) => i['id'] == id))) {
      throw const FormatException(
        'Choose a travel mode and one to six different interests.',
      );
    }
  }
}

class Person {
  Person({required this.id, required this.name, this.card});
  factory Person.fromJson(Json json) => Person(
    id: json['id'] as String,
    name: json['name'] as String,
    card: json['card'] == null
        ? null
        : PreferenceCard.fromJson(
            Map<String, dynamic>.from(json['card'] as Map),
          ),
  );
  final String id;
  String name;
  PreferenceCard? card;
  String get initials => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((s) => s.isEmpty ? '' : s[0])
      .join()
      .toUpperCase();
  Json toJson() => {'id': id, 'name': name, 'card': card?.toJson()};
}

class Activity {
  Activity(this.json);
  final Json json;
  String get id => json['id'] as String;
  String get name => json['name'] as String;
  String get venue => json['venue'] as String;
  String get area => json['area'] as String;
  String get description => json['description'] as String;
  String get url => json['url'] as String? ?? '';
  String get source => json['dataSource'] as String? ?? 'demo';
  String get theme => json['theme'] as String? ?? 'art';
  String get photo =>
      const {
        'studio': 'art',
        'library': 'coffee',
        'market': 'food',
        'picnic': 'park',
        'water': 'water',
      }[theme] ??
      theme;
  double get lat => (json['lat'] as num).toDouble();
  double get lng => (json['lng'] as num).toDouble();
  int get cost => json['cost'] as int;
  int get duration => json['duration'] as int;
  int get noise => json['noise'] as int;
  bool get indoor => json['indoor'] as bool;
  bool? get stepFree => json['stepFree'] as bool?;
  List<String> get tags => List<String>.from(json['tags'] as List);
  List<List<int>> get windows =>
      (json['windows'] as List).map((w) => List<int>.from(w as List)).toList();
}

class Experience {
  Experience.fromJson(Json json)
    : areas = List<Json>.from(json['areas'] as List),
      interests = List<Json>.from(json['interests'] as List),
      catalog = (json['catalog'] as List)
          .map((x) => Activity(Map<String, dynamic>.from(x as Map)))
          .toList(),
      samplePeople = (json['members'] as List)
          .map((x) => Person.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList(),
      defaultCard = PreferenceCard.fromJson(
        Map<String, dynamic>.from(json['defaultCard'] as Map),
      );
  final List<Json> areas, interests;
  final List<Activity> catalog;
  final List<Person> samplePeople;
  final PreferenceCard defaultCard;

  Activity optionCandidate(Json option) {
    validateOption(option);
    final area = areas.firstWhere((a) => a['id'] == option['areaId']);
    final tags = List<String>.from(option['tags'] as List);
    return Activity({
      ...option,
      'area': area['name'],
      'lat': option['lat'] ?? area['lat'],
      'lng': option['lng'] ?? area['lng'],
      'duration': option['duration'] ?? 90,
      'windows': [
        [option['opens'], option['closes']],
      ],
      'dataSource': 'host',
      'theme': const {
        'games': 'games',
        'art': 'art',
        'food': 'market',
        'coffee': 'library',
        'outdoors': 'park',
        'music': 'water',
      }[tags.first],
    });
  }

  void validateOption(Json option) {
    for (final (field, maxLength) in [
      ('name', 70),
      ('venue', 100),
      ('description', 300),
    ]) {
      final value = option[field];
      if (value is! String ||
          value.trim().isEmpty ||
          value.length > maxLength) {
        throw FormatException('Check the activity $field.');
      }
    }
    final url = option['url'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (url is! String ||
        url.length > 1000 ||
        (url.isNotEmpty && (uri?.scheme != 'https' || uri!.host.isEmpty))) {
      throw const FormatException('Activity links must use HTTPS.');
    }
    if (!areas.any((a) => a['id'] == option['areaId']) ||
        option['cost'] is! int ||
        (option['cost'] as int) < 0 ||
        (option['cost'] as int) > 200 ||
        ![1, 2, 3].contains(option['noise']) ||
        option['indoor'] is! bool ||
        ![null, true].contains(option['stepFree'])) {
      throw const FormatException(
        'Check the activity location, cost and setting.',
      );
    }
    final tags = option['tags'];
    final facts = option['sourceFacts'];
    if (facts != null &&
        (facts is! Map ||
            facts.length != 3 ||
            !['hours', 'fee', 'access'].every(
              (key) =>
                  facts[key] is String && (facts[key] as String).length <= 300,
            ))) {
      throw const FormatException('Check the venue source details.');
    }
    final duration = option['duration'] ?? 90;
    if (duration is! int || duration < 30 || duration > 240) {
      throw const FormatException(
        'Choose an activity length from 30 to 240 minutes.',
      );
    }
    if ((option['lat'] != null || option['lng'] != null) &&
        (option['lat'] is! num ||
            option['lng'] is! num ||
            (option['lat'] as num) < 43.4 ||
            (option['lat'] as num) > 44.0 ||
            (option['lng'] as num) < -80 ||
            (option['lng'] as num) > -78.8)) {
      throw const FormatException('Choose a place in the Toronto area.');
    }
    if (tags is! List ||
        tags.isEmpty ||
        tags.length > 6 ||
        tags.toSet().length != tags.length ||
        tags.any((t) => !interests.any((i) => i['id'] == t))) {
      throw const FormatException('Choose valid activity interests.');
    }
    if (option['opens'] is! int ||
        option['closes'] is! int ||
        (option['opens'] as int) < 360 ||
        (option['closes'] as int) > 1440 ||
        (option['closes'] as int) - (option['opens'] as int) < duration) {
      throw const FormatException(
        'Allow enough time for the chosen activity length.',
      );
    }
  }
}

class Proposal {
  Proposal(
    this.candidateId,
    this.startMinute,
    this.revision, {
    this.stops = const [],
  });
  factory Proposal.fromJson(Json json) => Proposal(
    json['candidateId'] as String,
    json['startMinute'] as int,
    json['revision'] as int,
    stops: List<Json>.from(json['stops'] as List? ?? []),
  );
  final String candidateId;
  final int startMinute, revision;
  final List<Json> stops;
  Json toJson() => {
    'candidateId': candidateId,
    'startMinute': startMinute,
    'revision': revision,
    if (stops.isNotEmpty) 'stops': stops,
  };
}

class PlanVote {
  PlanVote(this.choice, this.candidateId, this.revision);
  factory PlanVote.fromJson(Json json) => PlanVote(
    json['choice'] as String,
    json['candidateId'] as String,
    json['revision'] as int,
  );
  final String choice, candidateId;
  final int revision;
  Json toJson() => {
    'choice': choice,
    'candidateId': candidateId,
    'revision': revision,
  };
}

class PlanRoom {
  PlanRoom({
    required this.id,
    required this.title,
    required this.date,
    required this.ownerId,
    required this.members,
    this.local = true,
    this.status = 'gathering',
    this.revision = 0,
    this.proposal,
    this.inviteId,
    this.travelSource = 'estimate',
    Map<String, Json>? routes,
    Map<String, PlanVote>? votes,
    List<Json>? options,
  }) : votes = votes ?? {},
       options = options ?? [],
       routes = routes ?? {};
  factory PlanRoom.fromJson(Json json) => PlanRoom(
    id: json['id'] as String,
    title: json['title'] as String,
    date: json['date'] as String,
    ownerId: json['ownerId'] as String,
    members: (json['members'] as List)
        .map((p) => Person.fromJson(Map<String, dynamic>.from(p as Map)))
        .toList(),
    local: json['local'] as bool? ?? true,
    status: json['status'] as String? ?? 'gathering',
    revision: json['revision'] as int? ?? 0,
    inviteId: json['inviteId'] as String?,
    proposal: json['proposal'] == null
        ? null
        : Proposal.fromJson(Map<String, dynamic>.from(json['proposal'] as Map)),
    votes: (json['votes'] as Map? ?? {}).map(
      (k, v) => MapEntry(
        k as String,
        PlanVote.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    ),
    options: List<Json>.from(json['options'] as List? ?? []),
    travelSource: json['travelSource'] as String? ?? 'estimate',
    routes: (json['routes'] as Map? ?? {}).map(
      (k, v) => MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
    ),
  );
  final String id;
  String title, date, ownerId;
  final bool local;
  final String? inviteId;
  List<Person> members;
  List<Json> options;
  String travelSource;
  Map<String, Json> routes;
  Map<String, PlanVote> votes;
  String status;
  int revision;
  Proposal? proposal;
  bool get allReady =>
      members.isNotEmpty && members.every((m) => m.card != null);
  bool get canConfirm =>
      proposal != null &&
      members.length >= 2 &&
      allReady &&
      members.every(
        (m) =>
            votes[m.id]?.choice == 'yes' &&
            votes[m.id]?.revision == proposal!.revision &&
            votes[m.id]?.candidateId == proposal!.candidateId,
      );
  void reset() {
    revision++;
    proposal = null;
    votes = {};
    status = 'gathering';
  }

  Json toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'ownerId': ownerId,
    'members': members.map((m) => m.toJson()).toList(),
    'local': local,
    'status': status,
    'revision': revision,
    'proposal': proposal?.toJson(),
    'inviteId': inviteId,
    'votes': votes.map((k, v) => MapEntry(k, v.toJson())),
    'options': options,
    'travelSource': travelSource,
    'routes': routes,
  };
}

class PersonFit {
  PersonFit(this.memberId, this.score, this.travel, this.matches);
  final String memberId;
  final int score, travel, matches;
}

class RankedPlan {
  RankedPlan({
    required this.candidate,
    required this.reasons,
    required this.fits,
    this.start,
  });
  final Activity candidate;
  final List<String> reasons;
  final List<PersonFit> fits;
  final int? start;
  bool get eligible => reasons.isEmpty;
  int get minFit => fits.map((f) => f.score).reduce(math.min);
  int get meanFit =>
      (fits.fold(0, (sum, f) => sum + f.score) / fits.length).round();
  int get maxTravel => fits.map((f) => f.travel).reduce(math.max);
}

class Planner {
  Planner(this.data, {this.room});
  final Experience data;
  final PlanRoom? room;
  late final String? _basis = room == null ? null : planningBasis(room!, data);
  bool get routed => room?.travelSource == 'routed';
  Json? routeFact(String key) {
    final current = room;
    final fact = current?.routes[key];
    if (current == null ||
        fact == null ||
        fact['basis'] != _basis ||
        (fact['expiresAt'] as int? ?? 0) <=
            DateTime.now().millisecondsSinceEpoch) {
      return null;
    }
    return fact;
  }

  int routedMinutes(String key, String? memberId) {
    final value = (routeFact(key)?['minutes'] as Map?)?[memberId];
    return value is int && value >= 0 && value <= 300 ? value : 9999;
  }

  double distance(double lat1, double lng1, double lat2, double lng2) {
    double rad(double d) => d * math.pi / 180;
    final x =
        math.pow(math.sin(rad(lat2 - lat1) / 2), 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.pow(math.sin(rad(lng2 - lng1) / 2), 2);
    return 6371 * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  int travel(PreferenceCard card, Activity activity, {String? memberId}) {
    if (routed) return routedMinutes('start__${activity.id}', memberId);
    final area = data.areas.firstWhere((a) => a['id'] == card.areaId);
    final speed = {'transit': 18.0, 'walk': 4.5, 'bike': 12.0}[card.mode]!;
    return (distance(
                  (area['lat'] as num).toDouble(),
                  (area['lng'] as num).toDouble(),
                  activity.lat,
                  activity.lng,
                ) *
                1.35 /
                speed *
                60 +
            (card.mode == 'transit' ? 10 : 3))
        .ceil();
  }

  int between(Activity from, Activity to, String mode, {String? memberId}) {
    if (routed) return routedMinutes('${from.id}__${to.id}', memberId);
    final speed = {'transit': 18.0, 'walk': 4.5, 'bike': 12.0}[mode]!;
    return (distance(from.lat, from.lng, to.lat, to.lng) * 1.35 / speed * 60 +
            (mode == 'transit' ? 10 : 3))
        .ceil();
  }

  /// An ordered itinerary uses the same hard limits for the whole outing.
  Itinerary itinerary(List<Activity> activities, List<Person> people) {
    final reasons = <String>[];
    if (activities.length < 2 ||
        activities.length > 3 ||
        activities.map((a) => a.id).toSet().length != activities.length) {
      return Itinerary(
        [],
        ['Choose two or three different activities.'],
        0,
        {},
      );
    }
    if (people.length < 2 || people.any((p) => p.card == null)) {
      return Itinerary(
        [],
        ['Everyone must share their preferences first.'],
        0,
        {},
      );
    }
    final cards = people.map((p) => p.card!).toList();
    final cost = activities.fold<int>(0, (sum, a) => sum + a.cost);
    if (cards.any((c) => cost > c.maxSpend)) {
      reasons.add('The total cost exceeds someone’s spending limit.');
    }
    var cursor = cards.map((c) => c.earliest).reduce(math.max);
    final end = cards.map((c) => c.latest).reduce(math.min);
    final totalTravel = <String, int>{};
    final stops = <Json>[];
    for (var i = 0; i < activities.length; i++) {
      final activity = activities[i];
      var transfer = 0;
      for (final person in people) {
        final c = person.card!;
        final minutes = i == 0
            ? travel(c, activity, memberId: person.id)
            : between(activities[i - 1], activity, c.mode, memberId: person.id);
        if (minutes == 9999) {
          reasons.add('Refresh sourced routes for every person and stop.');
        }
        totalTravel[person.id] = (totalTravel[person.id] ?? 0) + minutes;
        if (i > 0) transfer = math.max(transfer, minutes);
        if ((c.quiet && activity.noise > 1) ||
            (c.indoors && !activity.indoor) ||
            (c.stepFree && activity.stepFree != true)) {
          reasons.add(
            '${activity.name} does not meet everyone’s setting or access requirements.',
          );
        }
      }
      cursor += transfer;
      int? start;
      for (final window in activity.windows) {
        final possible = math.max(cursor, window[0]);
        if (possible + activity.duration <= math.min(end, window[1])) {
          start = possible;
          break;
        }
      }
      if (start == null) {
        reasons.add(
          'There is not enough shared time for ${activity.name} and travel between stops.',
        );
        break;
      }
      if (routed) {
        final key = i == 0
            ? 'start__${activity.id}'
            : '${activities[i - 1].id}__${activity.id}';
        if (routeFact(key)?['arrivalMinute'] != start) {
          reasons.add('Refresh route times for this itinerary’s schedule.');
        }
      }
      stops.add({
        'candidateId': activity.id,
        'startMinute': start,
        'duration': activity.duration,
        'transferMinutes': transfer,
      });
      cursor = start + activity.duration;
    }
    for (final person in people) {
      if ((totalTravel[person.id] ?? 0) > person.card!.maxTravel) {
        reasons.add('Total travel exceeds ${person.name}’s travel limit.');
      }
    }
    return Itinerary(stops, reasons.toSet().toList(), cost, totalTravel);
  }

  RankedPlan evaluate(Activity activity, List<Person> members) {
    if (members.isEmpty || members.any((m) => m.card == null)) {
      return RankedPlan(
        candidate: activity,
        reasons: ['Waiting for everyone’s preferences.'],
        fits: [],
      );
    }
    final cards = members.map((m) => m.card!).toList();
    for (final card in cards) {
      card.validate(data);
    }
    final earliest = cards.map((c) => c.earliest).reduce(math.max);
    final latest = cards.map((c) => c.latest).reduce(math.min);
    int? start;
    for (final w in activity.windows) {
      final a = math.max(w[0], earliest), b = math.min(w[1], latest);
      if (b - a >= activity.duration) {
        start = a;
        break;
      }
    }
    final travels = cards.indexed
        .map((p) => travel(p.$2, activity, memberId: members[p.$1].id))
        .toList();
    final reasons = <String>[
      if (routed &&
          (travels.contains(9999) ||
              routeFact('start__${activity.id}')?['arrivalMinute'] != start))
        'Current sourced routes are required for everyone at this start time.',
      if (start == null) 'No shared ${activity.duration}-minute time window.',
      if (cards.any((c) => activity.cost > c.maxSpend))
        'Above someone’s shared spending limit.',
      if (cards.indexed.any((p) => travels[p.$1] > p.$2.maxTravel))
        'Beyond someone’s travel limit.',
      if (cards.any((c) => c.quiet) && activity.noise > 1)
        'Doesn’t meet the quiet-setting requirement.',
      if (cards.any((c) => c.indoors) && !activity.indoor)
        'An indoor setting is required.',
      if (cards.any((c) => c.stepFree) && activity.stepFree != true)
        'Step-free access hasn’t been confirmed.',
    ];
    final fits = cards.indexed.map((pair) {
      final (i, c) = pair;
      final matches = c.interests.where(activity.tags.contains).length;
      final interest =
          matches / math.min(c.interests.length, activity.tags.length);
      final affordability = c.maxSpend == 0
          ? 1.0
          : 1 - activity.cost / math.max(c.maxSpend, 1);
      final convenience = 1 - math.min(travels[i] / c.maxTravel, 1);
      return PersonFit(
        members[i].id,
        (45 + interest * 30 + affordability * 10 + convenience * 15)
            .round()
            .clamp(0, 100),
        travels[i],
        matches,
      );
    }).toList();
    return RankedPlan(
      candidate: activity,
      reasons: reasons,
      fits: fits,
      start: start,
    );
  }

  List<RankedPlan> rank(List<Person> members, [List<Activity>? catalog]) {
    final eligible = (catalog ?? data.catalog)
        .map((a) => evaluate(a, members))
        .where((r) => r.eligible)
        .toList();
    eligible.sort(
      (a, b) => b.minFit.compareTo(a.minFit) != 0
          ? b.minFit.compareTo(a.minFit)
          : b.meanFit.compareTo(a.meanFit) != 0
          ? b.meanFit.compareTo(a.meanFit)
          : a.maxTravel.compareTo(b.maxTravel) != 0
          ? a.maxTravel.compareTo(b.maxTravel)
          : a.candidate.cost.compareTo(b.candidate.cost) != 0
          ? a.candidate.cost.compareTo(b.candidate.cost)
          : a.candidate.id.compareTo(b.candidate.id),
    );
    return eligible;
  }

  List<Activity> catalogFor(PlanRoom room) => room.options.isEmpty
      ? data.catalog
      : room.options.map(data.optionCandidate).toList();
}

class Itinerary {
  Itinerary(this.stops, this.reasons, this.cost, this.travel);
  final List<Json> stops;
  final List<String> reasons;
  final int cost;
  final Map<String, int> travel;
  bool get eligible => reasons.isEmpty && stops.length >= 2;
}

String planningBasis(PlanRoom room, Experience data) {
  final members = [...room.members]..sort((a, b) => a.id.compareTo(b.id));
  final activities = [...Planner(data).catalogFor(room)]
    ..sort((a, b) => a.id.compareTo(b.id));
  return sha256
      .convert(
        utf8.encode(
          jsonEncode({
            'date': room.date,
            'members': members
                .map((p) => {'id': p.id, 'card': p.card?.toJson()})
                .toList(),
            'activities': activities
                .map(
                  (a) => {
                    'id': a.id,
                    'lat': a.lat,
                    'lng': a.lng,
                    'windows': a.windows,
                    'duration': a.duration,
                  },
                )
                .toList(),
          }),
        ),
      )
      .toString();
}

List<Activity> proposalActivities(PlanRoom room, List<Activity> catalog) {
  final proposal = room.proposal;
  if (proposal == null) return [];
  final ids = proposal.stops.isEmpty
      ? [proposal.candidateId]
      : proposal.stops.map((s) => s['candidateId'] as String).toList();
  return ids
      .map((id) => catalog.where((a) => a.id == id).firstOrNull)
      .whereType<Activity>()
      .toList();
}

String timeLabel(int minute) {
  final h = (minute ~/ 60) % 24, m = minute % 60;
  return '${h % 12 == 0 ? 12 : h % 12}${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}${h < 12 ? 'am' : 'pm'}';
}

String isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime torontoInstant(String day, int minutes) {
  final date = DateTime.parse(day);
  int sunday(int month, int ordinal) {
    final first = DateTime.utc(date.year, month, 1);
    return 1 + (DateTime.sunday - first.weekday + 7) % 7 + (ordinal - 1) * 7;
  }

  final local = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).add(Duration(minutes: minutes));
  final daylightStart = DateTime.utc(date.year, 3, sunday(3, 2), 2);
  final daylightEnd = DateTime.utc(date.year, 11, sunday(11, 1), 2);
  final daylight =
      !local.isBefore(daylightStart) && local.isBefore(daylightEnd);
  return local.add(Duration(hours: daylight ? 4 : 5));
}

String nextSaturday([DateTime? now]) {
  final date = now ?? DateTime.now();
  final days = (DateTime.saturday - date.weekday + 7) % 7;
  return isoDate(
    DateTime(date.year, date.month, date.day + (days == 0 ? 7 : days)),
  );
}

String calendarFile(
  PlanRoom room,
  Activity activity, [
  List<Activity>? itinerary,
]) {
  final activities = itinerary ?? [activity];
  final totalCost = activities.fold<int>(0, (sum, a) => sum + a.cost);
  final lastStop = room.proposal!.stops.lastOrNull;
  final endMinute = lastStop == null
      ? room.proposal!.startMinute + activity.duration
      : (lastStop['startMinute'] as int) + (lastStop['duration'] as int);
  String escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('\n', '\\n')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;');
  final date = DateTime.parse('${room.date}T00:00:00Z');
  String stamp(int minutes) {
    final t = date.add(Duration(minutes: minutes));
    return '${isoDate(t).replaceAll('-', '')}T${t.hour.toString().padLeft(2, '0')}${t.minute.toString().padLeft(2, '0')}00';
  }

  // RFC 5545 folds content lines longer than 75 octets.
  String fold(String line) {
    final out = StringBuffer();
    var octets = 0;
    for (final rune in line.runes) {
      final char = String.fromCharCode(rune), size = utf8.encode(char).length;
      if (octets + size > 75) {
        out.write('\r\n ');
        octets = 1;
      }
      out.write(char);
      octets += size;
    }
    return out.toString();
  }

  final cost = totalCost == 0 ? 'free' : 'about \$$totalCost per person';
  final schedule = room.proposal!.stops
      .map((stop) {
        final item = activities
            .where((a) => a.id == stop['candidateId'])
            .firstOrNull;
        return '${timeLabel(stop["startMinute"] as int)}: ${item?.name ?? "Activity"} at ${item?.venue ?? "venue"} (${stop["duration"]} min)';
      })
      .join('; ');
  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//MeetHalfway//Flutter//EN',
    'BEGIN:VTIMEZONE',
    'TZID:America/Toronto',
    'BEGIN:STANDARD',
    'DTSTART:19701101T020000',
    'RRULE:FREQ=YEARLY;BYMONTH=11;BYDAY=1SU',
    'TZOFFSETFROM:-0400',
    'TZOFFSETTO:-0500',
    'TZNAME:EST',
    'END:STANDARD',
    'BEGIN:DAYLIGHT',
    'DTSTART:19700308T020000',
    'RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=2SU',
    'TZOFFSETFROM:-0500',
    'TZOFFSETTO:-0400',
    'TZNAME:EDT',
    'END:DAYLIGHT',
    'END:VTIMEZONE',
    'BEGIN:VEVENT',
    'UID:${room.id}-${room.proposal!.revision}@meethalfway.app',
    'DTSTAMP:${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z',
    'DTSTART;TZID=America/Toronto:${stamp(room.proposal!.startMinute)}',
    'DTEND;TZID=America/Toronto:${stamp(endMinute)}',
    'SUMMARY:${escape(activities.map((a) => a.name).join(' → '))}',
    'LOCATION:${escape('${activities.map((a) => a.venue).join(' → ')}, Toronto')}',
    'DESCRIPTION:${escape('${room.title}. ${schedule.isEmpty ? "" : "$schedule. "}Estimated cost: $cost. Nothing is booked: confirm current hours, prices and any reservation before travelling.')}',
    'END:VEVENT',
    'END:VCALENDAR',
  ].map(fold).join('\r\n');
}
