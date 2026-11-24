import 'package:cloud_firestore/cloud_firestore.dart';

import 'domain.dart';
import 'firebase_service.dart';

extension FirebasePlans on FirebaseService {
  Future<void> recordActivity(String roomId, String type, int revision) async {
    try {
      await db.doc('rooms/$roomId/events/$uid-$type-$revision').set({
        'type': type,
        'actorId': uid,
        'revision': revision,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      /* A notification failure must not undo a completed decision. */
    }
  }

  Future<void> editPlan(PlanRoom room, String title, String date) async {
    await connect();
    await db.runTransaction((tx) async {
      final ref = db.doc('rooms/${room.id}');
      final data = (await tx.get(ref)).data()!;
      if (data['revision'] != room.revision) {
        throw StateError('The group changed. Try again.');
      }
      tx.update(ref, {
        'title': title,
        'date': date,
        'status': 'gathering',
        'proposal': null,
        'revision': room.revision + 1,
      });
    });
    await recordActivity(room.id, 'plan', room.revision + 1);
  }

  Future<void> renameMember(PlanRoom room, String name) async {
    await connect();
    final batch = db.batch();
    batch.update(db.doc('rooms/${room.id}/members/$uid'), {
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.update(db.doc('rooms/${room.id}'), {
      'status': 'gathering',
      'proposal': null,
      'revision': FieldValue.increment(1),
    });
    await batch.commit();
    await recordActivity(room.id, 'plan', room.revision + 1);
  }

  Future<void> editOption(PlanRoom room, String id, Json? option) async {
    await connect();
    await db.runTransaction((tx) async {
      final ref = db.doc('rooms/${room.id}');
      final data = (await tx.get(ref)).data()!;
      if (data['revision'] != room.revision) {
        throw StateError('The group changed. Try again.');
      }
      final optionRef = db.doc('rooms/${room.id}/options/$id');
      if (option == null) {
        tx.delete(optionRef);
      } else {
        tx.update(optionRef, {
          ...option,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(db.doc('rooms/${room.id}/members/$uid'), {
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(ref, {
        'status': 'gathering',
        'proposal': null,
        'revision': room.revision + 1,
      });
    });
    await recordActivity(room.id, 'options', room.revision + 1);
  }

  Future<void> transferHost(PlanRoom room, String nextOwner) async {
    await connect();
    await db.doc('rooms/${room.id}').update({
      'ownerId': nextOwner,
      'status': 'gathering',
      'proposal': null,
      'revision': FieldValue.increment(1),
    });
    await recordActivity(room.id, 'plan', room.revision + 1);
  }

  Future<void> removeMember(PlanRoom room, String memberId) async {
    await connect();
    // A departing host must transfer ownership or delete the plan first.
    await db.runTransaction((tx) async {
      final ref = db.doc('rooms/${room.id}');
      final snapshot = (await tx.get(ref)).data()!;
      final members = List<String>.from(snapshot['memberIds'] as List);
      if (snapshot['ownerId'] == memberId) {
        throw StateError('Transfer hosting before leaving.');
      }
      if (!members.remove(memberId)) {
        throw StateError('That person already left.');
      }
      tx.delete(db.doc('rooms/${room.id}/members/$memberId'));
      tx.delete(db.doc('rooms/${room.id}/votes/$memberId'));
      tx.update(ref, {
        'memberIds': members,
        'status': 'gathering',
        'proposal': null,
        'revision': FieldValue.increment(1),
      });
    });
  }

  Future<String> revokeInvitations(PlanRoom room) async {
    await connect();
    final token = randomId(24), batch = db.batch();
    batch.update(db.doc('rooms/${room.id}'), {'lastJoinInviteId': token});
    batch.set(db.doc('invites/$token'), {
      'roomId': room.id,
      'title': room.title,
      'createdBy': uid,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(FirebaseService.inviteLifetime),
      ),
    });
    await batch.commit();
    return token;
  }

  /// Small bounded subcollections are purged before the parent. The room is
  /// marked deleting first, so a concurrent join/write cannot create orphans.
  Future<void> deletePlan(PlanRoom room) async {
    await connect();
    final ref = db.doc('rooms/${room.id}');
    await ref.update({'deleting': true});
    for (final path in ['votes', 'options', 'routes', 'events', 'members']) {
      while (true) {
        final docs = await ref.collection(path).limit(100).get();
        if (docs.docs.isEmpty) break;
        final batch = db.batch();
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }
    while (true) {
      final invites = await db
          .collection('invites')
          .where('roomId', isEqualTo: room.id)
          .limit(100)
          .get();
      if (invites.docs.isEmpty) break;
      final batch = db.batch();
      for (final doc in invites.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await ref.delete();
  }
}
