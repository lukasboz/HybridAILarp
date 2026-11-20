import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meet_halfway/domain.dart';
import 'package:meet_halfway/firebase_service.dart';
import 'package:meet_halfway/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        '2026-11-21',
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
}
