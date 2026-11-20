import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_test/flutter_test.dart';
import 'package:meet_halfway/domain.dart';
import 'package:meet_halfway/firebase_service.dart';
import 'package:meet_halfway/store.dart';

class TestCloud extends FirebaseService {
  TestCloud(ModelRequest request) : super({}, modelRequest: request);
  @override
  Future<void> connect() async {
    connected = true;
  }
}

void main() {
  final data = Experience.fromJson(
    jsonDecode(File('../shared/experience.json').readAsStringSync()) as Json,
  );
  final cardJson = jsonEncode(data.defaultCard.toJson());
  const busyMessage =
      'Server Error [500]: This model is currently experiencing high demand.';

  test(
    'successful primary draft uses one request and records its model',
    () async {
      final calls = <String>[];
      final cloud = TestCloud((model, prompt) async {
        calls.add(model);
        return cardJson;
      });
      final (card, receipt) = await cloud.extractNote(
        'Synthetic note',
        data.defaultCard,
        data,
      );
      expect(card.toJson(), data.defaultCard.toJson());
      expect(calls, ['gemini-3.8-flash']);
      expect(receipt.model, 'gemini-3.8-flash');
    },
  );

  test(
    'model overload falls back once and reports the model actually used',
    () async {
      final calls = <String>[];
      final cloud = TestCloud((model, prompt) async {
        calls.add(model);
        if (model == 'gemini-3.8-flash') throw FirebaseAIException(busyMessage);
        return cardJson;
      });
      final (_, receipt) = await cloud.extractNote(
        'Synthetic note',
        data.defaultCard,
        data,
      );
      expect(calls, ['gemini-3.8-flash', 'gemini-3.5-flash-lite']);
      expect(receipt.model, 'gemini-3.5-flash-lite');
    },
  );

  test(
    'failed models explain capacity instead of blaming connectivity',
    () async {
      var calls = 0;
      final cloud = TestCloud((model, prompt) async {
        calls++;
        throw FirebaseAIException(busyMessage);
      });
      try {
        await cloud.extractNote('Synthetic note', data.defaultCard, data);
        fail('Both models should have failed.');
      } on CloudAIException catch (error) {
        expect(error.kind, CloudAIError.busy);
        expect(friendlyError(error), contains('busy'));
        expect(friendlyError(error), isNot(contains('connection')));
      }
      expect(calls, 2);
    },
  );

  test(
    'App Check failures stay explicit and do not use another model',
    () async {
      var calls = 0;
      final cloud = TestCloud((model, prompt) async {
        calls++;
        throw FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unknown',
          message: 'App attestation failed: PRIVATE_IDENTIFIER',
        );
      });
      try {
        await cloud.extractNote('Synthetic note', data.defaultCard, data);
        fail('Device verification should fail.');
      } on CloudAIException catch (error) {
        expect(error.kind, CloudAIError.verification);
        expect(friendlyError(error), contains('verify this device'));
        expect(friendlyError(error), isNot(contains('PRIVATE_IDENTIFIER')));
      }
      expect(calls, 1);
    },
  );

  test('invalid API configuration is not retried on another model', () async {
    var calls = 0;
    final cloud = TestCloud((model, prompt) async {
      calls++;
      throw InvalidApiKey('PRIVATE_KEY_DETAILS');
    });
    await expectLater(
      cloud.extractNote('Synthetic note', data.defaultCard, data),
      throwsA(
        isA<CloudAIException>().having(
          (e) => e.kind,
          'kind',
          CloudAIError.configuration,
        ),
      ),
    );
    expect(calls, 1);
  });

  test('timed-out primary request can use the fallback', () async {
    final cloud = TestCloud((model, prompt) async {
      if (model == 'gemini-3.8-flash') {
        throw TimeoutException('Synthetic timeout');
      }
      return cardJson;
    });
    final (_, receipt) = await cloud.extractNote(
      'Synthetic note',
      data.defaultCard,
      data,
    );
    expect(receipt.model, 'gemini-3.5-flash-lite');
  });

  test('shortlist explanation receipt also records the fallback', () async {
    final room = PlanRoom(
      id: 'test',
      title: 'A test',
      date: '2026-11-21',
      ownerId: 'alex',
      members: data.samplePeople,
    );
    final plans = Planner(data).rank(room.members);
    final cloud = TestCloud((model, prompt) async {
      if (model == 'gemini-3.8-flash') throw FirebaseAIException(busyMessage);
      return jsonEncode({
        'explanations': [
          {
            'id': plans.first.candidate.id,
            'reason': 'Fits the approved cards.',
            'tradeoff': 'Travel is estimated.',
          },
        ],
      });
    });
    final (explanations, receipt) = await cloud.explain(room, plans);
    expect(explanations.single.id, plans.first.candidate.id);
    expect(receipt.model, 'gemini-3.5-flash-lite');
  });

  test(
    'shortlist explanations send cards without member identifiers',
    () async {
      final room = PlanRoom(
        id: 'test',
        title: 'A test',
        date: '2026-11-21',
        ownerId: 'alex',
        members: data.samplePeople,
      );
      final plans = Planner(data).rank(room.members);
      late String sent;
      final cloud = TestCloud((model, prompt) async {
        sent = prompt;
        return jsonEncode({
          'explanations': [
            {
              'id': plans.first.candidate.id,
              'reason': 'Fits the approved cards.',
              'tradeoff': 'Travel is estimated.',
            },
          ],
        });
      });
      await cloud.explain(room, plans);
      for (final person in room.members) {
        expect(sent, isNot(contains('"${person.id}"')));
      }
      expect(sent, contains('"person-1"'));
    },
  );
}
