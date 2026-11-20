import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meet_halfway/domain.dart';

void main() {
  final data = Experience.fromJson(
    jsonDecode(File('../shared/experience.json').readAsStringSync()) as Json,
  );
  final fixtures = jsonDecode(
    File('../shared/planner-cases.json').readAsStringSync(),
  ) as List;
  final planner = Planner(data);
  for (final fixture in fixtures) {
    test('Dart matches the shared planner contract: ${fixture['name']}', () {
      final people = (fixture['members'] as List)
          .map((p) => Person.fromJson(p as Json))
          .toList();
      final actual = planner
          .rank(people)
          .map(
            (r) => {
              'id': r.candidate.id,
              'minFit': r.minFit,
              'meanFit': r.meanFit,
              'maxTravel': r.maxTravel,
              'start': r.start,
            },
          )
          .toList();
      expect(actual, fixture['expected']);
    });
  }
  test('private notes and malformed cards cannot become approved cards', () {
    expect(
      () => PreferenceCard.fromJson({
        ...data.defaultCard.toJson(),
        'privateNote': 'PRIVATE_CANARY',
      }),
      throwsFormatException,
    );
    expect(
      () => data.defaultCard.copyWith(interests: ['art', 'art']).validate(data),
      throwsFormatException,
    );
    expect(
      () => data.defaultCard.copyWith(maxSpend: -1).validate(data),
      throwsFormatException,
    );
  });
  test(
    'consensus requires every current member on the exact proposal revision',
    () {
      final room = PlanRoom(
        id: 'test',
        title: 'A plan',
        date: '2026-11-21',
        ownerId: 'alex',
        members: data.samplePeople,
      );
      room.proposal = Proposal('college-games', 1020, 2);
      for (final person in room.members) {
        room.votes[person.id] = PlanVote('yes', 'college-games', 2);
      }
      expect(room.canConfirm, isTrue);
      room.votes['maya'] = PlanVote('yes', 'college-games', 1);
      expect(room.canConfirm, isFalse);
      room.votes['maya'] = PlanVote('yes', 'ago', 2);
      expect(room.canConfirm, isFalse);
      room.reset();
      expect(room.proposal, isNull);
      expect(room.votes, isEmpty);
    },
  );
  test('calendar rolls midnight and escapes user-controlled text', () {
    final room = PlanRoom(
      id: 'calendar',
      title: 'Evening',
      date: '2026-11-01',
      ownerId: 'alex',
      members: data.samplePeople,
      proposal: Proposal(data.catalog.first.id, 1350, 1),
    );
    final idea = Activity({
      ...data.catalog.first.json,
      'name': 'Games; friends, together',
    });
    final calendar = calendarFile(room, idea);
    expect(calendar, contains('DTEND;TZID=America/Toronto:20261102T000000'));
    expect(calendar, contains(r'SUMMARY:Games\; friends\, together'));
  });
  test(
    'host activities replace samples and must still pass hard constraints',
    () {
      final option = {
        'id': 'option-01',
        'name': 'Our game night',
        'venue': 'A local café',
        'areaId': 'downtown',
        'cost': 200,
        'tags': ['games'],
        'noise': 1,
        'indoor': true,
        'stepFree': null,
        'description': 'A group activity.',
        'url': '',
        'opens': 960,
        'closes': 1320,
      };
      final room = PlanRoom(
        id: 'host',
        title: 'Host options',
        date: '2026-11-21',
        ownerId: 'alex',
        members: data.samplePeople,
        options: [option],
      );
      expect(planner.catalogFor(room).single.source, 'host');
      expect(planner.rank(room.members, planner.catalogFor(room)), isEmpty);
    },
  );
}
