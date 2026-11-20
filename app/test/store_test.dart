import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meet_halfway/domain.dart';
import 'package:meet_halfway/firebase_service.dart';
import 'package:meet_halfway/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CountingCloud extends FirebaseService {
  CountingCloud() : super({});
  int roomReads = 0;
  @override
  bool get configured => true;
  @override
  Future<List<PlanRoom>> rooms() async {
    roomReads++;
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MeetStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final data = Experience.fromJson(
      jsonDecode(File('../shared/experience.json').readAsStringSync()) as Json,
    );
    store = MeetStore(
      data,
      await SharedPreferences.getInstance(),
      FirebaseService({}),
    );
  });
  tearDown(() => store.dispose());
  test(
    'sample planning goes through unanimous voting and confirmation',
    () async {
      await store.openSample();
      await store.propose(store.ranked.first);
      await store.vote('yes');
      store.switchPerson('maya');
      await store.vote('maybe');
      store.switchPerson('alex');
      expect(store.room!.canConfirm, isFalse);
      await expectLater(store.confirm(), throwsStateError);
      store.switchPerson('maya');
      await store.vote('yes');
      store.switchPerson('jordan');
      await store.vote('yes');
      store.switchPerson('alex');
      await store.confirm();
      expect(store.room!.status, 'confirmed');
    },
  );
  test(
    'a changed preference invalidates the proposal and previous votes',
    () async {
      await store.openSample();
      await store.propose(store.ranked.first);
      await store.vote('yes');
      final revision = store.room!.revision;
      await store.shareCard(store.me!.card!.copyWith(maxSpend: 0));
      expect(store.room!.revision, revision + 1);
      expect(store.room!.proposal, isNull);
      expect(store.room!.votes, isEmpty);
      expect(store.room!.status, 'gathering');
    },
  );
  test(
    'a new local plan is persisted and supports sample perspectives',
    () async {
      await store.create(
        'A weekend together',
        nextSaturday(),
        'Sam',
        live: false,
      );
      expect(store.ranked, isEmpty);
      await store.shareCard(store.data.defaultCard);
      await store.addSamplePerson();
      store.switchPerson('alex');
      expect(store.myId, 'alex');
      expect(
        store.preferences.getString('meet.flutter.rooms'),
        contains('A weekend together'),
      );
    },
  );
  test('plans cannot be made for a past date', () async {
    await expectLater(
      store.create('Too late', '2020-01-01', 'Sam', live: false),
      throwsFormatException,
    );
    expect(store.room, isNull);
  });
  test('a confirmed plan cannot be replaced by a new proposal', () async {
    await store.openSample();
    await store.propose(store.ranked.first);
    for (final person in ['alex', 'maya', 'jordan']) {
      store.switchPerson(person);
      await store.vote('yes');
    }
    store.switchPerson('alex');
    await store.confirm();
    await expectLater(store.propose(store.ranked.last), throwsStateError);
    expect(store.room!.status, 'confirmed');
  });
  test('a reopened decision is explained until the next proposal', () async {
    await store.openSample();
    expect(store.reopenedNotice, isNull);
    await store.propose(store.ranked.first);
    await store.shareCard(store.me!.card!.copyWith(maxTravel: 119));
    expect(store.reopenedNotice, contains('Alex updated their preferences'));
    await store.propose(store.ranked.first);
    expect(store.reopenedNotice, isNull);
  });
  test('live plans reload on launch only after this device used one', () async {
    final cloud = CountingCloud();
    final live = MeetStore(store.data, store.preferences, cloud);
    addTearDown(live.dispose);
    await live.restoreLive();
    expect(cloud.roomReads, 0);
    await store.preferences.setBool('meet.flutter.live', true);
    await live.restoreLive();
    expect(cloud.roomReads, 1);
    await live.resetLocal();
    await live.restoreLive();
    expect(cloud.roomReads, 2);
  });
}
