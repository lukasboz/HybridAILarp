import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:meet_halfway/domain.dart';
import 'package:meet_halfway/firebase_service.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const enabled = bool.fromEnvironment('RUN_FIREBASE_LIVE_TEST');

  testWidgets(
    'registered native client authenticates, attests and shares an approved card',
    (tester) async {
      const debugToken = String.fromEnvironment('FIREBASE_TEST_DEBUG_TOKEN');
      expect(debugToken, isNotEmpty);
      final client = FirebaseService(
        (await FirebaseService.load()).config,
        appCheckDebugToken: debugToken,
      );
      expect(client.config['emulator'], isFalse);
      expect(client.configured, isTrue);
      await client.connect();
      final token = await FirebaseAppCheck.instanceFor(app: client.firebaseApp)
          .getToken(true);
      expect(token, isNotEmpty);
      final data = Experience.fromJson(
        jsonDecode(await rootBundle.loadString('assets/shared/experience.json'))
            as Json,
      );
      const testAi = bool.fromEnvironment('RUN_FIREBASE_AI_TEST');
      AIReceipt? receipt;
      if (testAi) {
        // Synthetic test data only; this bypasses no production UI consent.
        final (draft, result) = await client.extractNote(
          'This is a synthetic connection test. I want quiet indoor board games '
          'in the Annex, a budget of 30 CAD and at most 45 minutes by transit. '
          'Keep the existing available times.',
          data.defaultCard,
          data,
        );
        draft.validate(data);
        expect(draft.quiet, isTrue);
        expect(draft.indoors, isTrue);
        expect(draft.maxSpend, 30);
        expect(draft.interests, contains('games'));
        receipt = result;
      }
      final id = await client.createRoom(
        'Native connection check',
        nextSaturday(),
        'Connection test',
      );
      final room = await client
          .watchRoom(id)
          .firstWhere((r) => r.members.length == 1)
          .timeout(const Duration(seconds: 30));
      await client.shareCard(room, data.defaultCard, 'Connection test');
      final snapshot = await client.db
          .doc('rooms/$id/members/${client.uid}')
          .get(const GetOptions(source: Source.server));
      expect((snapshot.data()!['card'] as Map).keys.toSet(), cardKeys);
      expect((await client.rooms()).any((r) => r.id == id), isTrue);
      binding.reportData = {
        'backend': 'configured Firebase project',
        'projectId': client.firebaseApp.options.projectId,
        'appId': client.firebaseApp.options.appId,
        'anonymousAuth': true,
        'appCheckAttested': true,
        'serverCardRead': true,
        'roomId': id,
        'memberId': client.uid,
        'inviteId': room.inviteId,
        'cloudAiCalled': testAi,
        if (receipt != null) 'cloudModel': receipt.model,
      };
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
