import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meet_halfway/domain.dart';
import 'package:meet_halfway/firebase_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real native clients join, share cards, reject stale votes and confirm unanimously',
    (tester) async {
      const project = 'demo-meethalfway';
      const host = String.fromEnvironment(
        'FIREBASE_EMULATOR_HOST',
        defaultValue: '10.0.2.2',
      );
      final config = <String, dynamic>{
        'emulator': true,
        'emulatorHost': host,
        for (final platform in ['android', 'ios', 'web'])
          platform: {
            'apiKey': 'fake-api-key',
            'appId': '1:1234567890:$platform:0123456789abcdef',
            'projectId': project,
            'messagingSenderId': '1234567890',
          },
      };
      final clients = List.generate(
        4,
        (i) => FirebaseService(
          config,
          appName: i == 0
              ? '[DEFAULT]'
              : 'integration-${DateTime.now().microsecondsSinceEpoch}-$i',
        ),
      );
      final [alex, maya, jordan, outsider] = clients;
      addTearDown(() async {
        for (final client in clients.reversed) {
          if (client.connected) {
            await client.auth.signOut();
            await client.db.terminate();
            if (client.appName != '[DEFAULT]') {
              await client.firebaseApp.delete();
            }
          }
        }
      });
      final data = Experience.fromJson(
        jsonDecode(await rootBundle.loadString('assets/shared/experience.json'))
            as Json,
      );
      final planner = Planner(data);
      for (final client in clients) {
        await client.connect();
      }
      expect(clients.map((c) => c.uid).toSet(), hasLength(4));

      Future<PlanRoom> waitFor(
        FirebaseService client,
        String id,
        bool Function(PlanRoom) predicate,
      ) => client
          .watchRoom(id)
          .firstWhere(predicate)
          .timeout(const Duration(seconds: 25));
      Matcher denied() => isA<FirebaseException>().having(
        (e) => e.code,
        'code',
        'permission-denied',
      );

      final id = await alex.createRoom(
        'Native integration test',
        '2026-11-28',
        'Alex',
      );
      var room = await waitFor(
        alex,
        id,
        (r) => r.members.length == 1 && r.members.first.name == 'Alex',
      );
      final token = room.inviteId!;
      await expectLater(outsider.db.doc('rooms/$id').get(), throwsA(denied()));
      await expectLater(
        outsider.db.collection('invites').get(),
        throwsA(denied()),
      );
      expect(await maya.join(token, 'Maya'), id);
      expect(await jordan.join(token, 'Jordan'), id);
      room = await waitFor(
        alex,
        id,
        (r) =>
            r.members.length == 3 &&
            r.members.every((m) => m.name != 'Joining…'),
      );
      final joinedRevision = room.revision;
      expect(await maya.join(token, 'Maya'), id);
      expect(
        (await alex.db.doc('rooms/$id').get()).data()!['revision'],
        joinedRevision,
      );

      await alex.shareCard(room, data.samplePeople[0].card!, 'Alex');
      await maya.shareCard(room, data.samplePeople[1].card!, 'Maya');
      await jordan.shareCard(room, data.samplePeople[2].card!, 'Jordan');
      room = await waitFor(alex, id, (r) => r.allReady);
      expect(planner.rank(room.members), isNotEmpty);

      await alex.addOption(room, {
        'name': 'Our actual game night',
        'venue': 'Host-selected café',
        'areaId': 'annex',
        'cost': 18,
        'tags': ['games'],
        'noise': 1,
        'indoor': true,
        'stepFree': null,
        'description': 'An activity provided by the host.',
        'url': '',
        'opens': 960,
        'closes': 1380,
      });
      room = await waitFor(
        alex,
        id,
        (r) => r.options.length == 1 && r.proposal == null,
      );
      final rank = planner.rank(room.members, planner.catalogFor(room)).first;
      expect(rank.candidate.source, 'host');
      await alex.propose(room, rank);
      room = await waitFor(alex, id, (r) => r.proposal != null);
      final firstRevision = room.proposal!.revision;
      await alex.vote(room, 'yes');
      await maya.vote(room, 'maybe');
      await expectLater(alex.confirm(room), throwsA(denied()));
      await expectLater(
        maya.db.doc('rooms/$id/votes/${jordan.uid}').set({
          'choice': 'yes',
          'candidateId': rank.candidate.id,
          'revision': firstRevision,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        throwsA(denied()),
      );

      await maya.shareCard(room, data.samplePeople[1].card!, 'Maya');
      room = await waitFor(
        alex,
        id,
        (r) => r.proposal == null && r.revision > firstRevision,
      );
      expect(room.canConfirm, isFalse);
      await alex.propose(
        room,
        planner.rank(room.members, planner.catalogFor(room)).first,
      );
      room = await waitFor(
        alex,
        id,
        (r) => r.proposal != null && r.proposal!.revision > firstRevision,
      );
      expect(room.canConfirm, isFalse);
      await expectLater(
        jordan.db.doc('rooms/$id/votes/${jordan.uid}').set({
          'choice': 'yes',
          'candidateId': rank.candidate.id,
          'revision': firstRevision,
          'updatedAt': FieldValue.serverTimestamp(),
        }),
        throwsA(denied()),
      );
      await alex.vote(room, 'yes');
      await maya.vote(room, 'yes');
      await jordan.vote(room, 'yes');
      room = await waitFor(alex, id, (r) => r.canConfirm);
      await alex.confirm(room);
      room = await waitFor(
        maya,
        id,
        (r) => r.status == 'confirmed' && r.canConfirm,
      );
      expect(room.canConfirm, isTrue);

      final member = (await alex.db.doc('rooms/$id/members/${alex.uid}').get())
          .data()!;
      expect((member['card'] as Map).keys.toSet(), cardKeys);
      await expectLater(
        alex.extractNote('SYNTHETIC_TEST_NOTE', data.defaultCard, data),
        throwsStateError,
      );
      binding.reportData = {
        'backend': 'local Auth + Firestore emulators',
        'independentClients': 4,
        'confirmedParticipants': 3,
        'staleVotesDenied': true,
        'outsiderReadsDenied': true,
        'cloudAiDisabledForEmulators': true,
      };
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
