import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_service.dart';

extension GuestAccountMerge on FirebaseService {
  /// Proves control of both identities before replacing a guest membership.
  /// The original session stays signed in if the destination password is wrong.
  Future<void> mergeGuestInto(String email, String password) async {
    await connect();
    final guestId = uid;
    if (!auth.currentUser!.isAnonymous) {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return;
    }
    final destination = await Firebase.initializeApp(
      name: 'merge-${randomId(8)}',
      options: firebaseApp.options,
    );
    final destinationAuth = FirebaseAuth.instanceFor(app: destination);
    try {
      if (config['emulator'] == true) {
        await destinationAuth.useAuthEmulator(
          config['emulatorHost'] as String? ?? '127.0.0.1',
          config['authPort'] as int? ?? 9099,
        );
      }
      await destinationAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final target = destinationAuth.currentUser!.uid;
      final requestId = '${guestId}_$target';
      final client = http.Client();
      try {
        final idToken = await destinationAuth.currentUser!.getIdToken();
        final appCheck = config['emulator'] == true
            ? null
            : await FirebaseAppCheck.instanceFor(app: firebaseApp).getToken();
        final root = config['emulator'] == true
            ? 'http://${config['emulatorHost'] ?? '127.0.0.1'}:${config['firestorePort'] ?? 8080}'
            : 'https://firestore.googleapis.com';
        final response = await client
            .patch(
              Uri.parse(
                '$root/v1/projects/${firebaseApp.options.projectId}/databases/(default)/documents/accountMigrations/$requestId',
              ),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
                'X-Firebase-AppCheck': ?appCheck,
              },
              body: jsonEncode({
                'fields': {
                  'guestId': {'stringValue': guestId},
                  'targetId': {'stringValue': target},
                  'expiresAt': {
                    'timestampValue': DateTime.now()
                        .toUtc()
                        .add(const Duration(minutes: 9))
                        .toIso8601String(),
                  },
                },
              }),
            )
            .timeout(const Duration(seconds: 20));
        if (response.statusCode != 200) {
          throw StateError(
            'Could not authorize account merging. Your guest identity and plans are unchanged.',
          );
        }
      } finally {
        client.close();
      }
      final rooms = await db
          .collection('rooms')
          .where('memberIds', arrayContains: guestId)
          .get();
      for (final room in rooms.docs) {
        await db.runTransaction((tx) async {
          final header = (await tx.get(room.reference)).data();
          if (header == null ||
              !(header['memberIds'] as List).contains(guestId)) {
            return;
          }
          if (header['deleting'] == true) {
            throw StateError(
              'Finish deleting ${header['title']} before merging your account.',
            );
          }
          final oldRef = room.reference.collection('members').doc(guestId);
          final newRef = room.reference.collection('members').doc(target);
          final oldMember = (await tx.get(oldRef)).data();
          final existing = await tx.get(newRef);
          if (oldMember == null) {
            throw StateError(
              'Your guest membership is unavailable. Reload this plan and try again.',
            );
          }
          final ids = List<String>.from(header['memberIds'] as List)
            ..remove(guestId);
          if (!ids.contains(target)) ids.add(target);
          if (!existing.exists) {
            tx.set(newRef, {
              ...oldMember,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          tx.delete(oldRef);
          tx.delete(room.reference.collection('votes').doc(guestId));
          tx.update(room.reference, {
            'memberIds': ids,
            'migrationTarget': target,
            'ownerId': header['ownerId'] == guestId
                ? target
                : header['ownerId'],
            'revision': (header['revision'] as int) + 1,
            'proposal': null,
            'status': 'gathering',
          });
        });
      }
      // Private guest defaults never overwrite an existing account profile.
      for (final collection in ['devices', 'inbox', 'delivery']) {
        while (true) {
          final documents = await db
              .collection('users/$guestId/$collection')
              .limit(100)
              .get();
          if (documents.docs.isEmpty) break;
          final batch = db.batch();
          for (final document in documents.docs) {
            batch.delete(document.reference);
          }
          await batch.commit();
        }
      }
      await db.doc('users/$guestId').delete();
      // Room migration is resumable: a network interruption leaves the guest
      // session usable for any rooms not yet transferred.
      await db.doc('accountMigrations/$requestId').delete();
      try {
        await auth.currentUser!.delete();
      } on FirebaseAuthException catch (error) {
        if (error.code != 'requires-recent-login') rethrow;
      }
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      // Cleanup must not hide a useful migration error or a successful sign-in.
      try {
        await destinationAuth.signOut();
      } catch (_) {}
      try {
        await destination.delete();
      } catch (_) {}
    }
  }
}
