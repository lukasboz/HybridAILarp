import 'package:cloud_firestore/cloud_firestore.dart';

import 'domain.dart';
import 'firebase_accounts.dart';
import 'firebase_service.dart';

extension SocialService on FirebaseService {
  Future<void> requireAccount() async {
    await connect();
    if (!hasAccount) {
      throw StateError(
        'Create or sign in to an account to keep your people across devices.',
      );
    }
  }

  Future<String> friendInvitation(String name) async {
    await requireAccount();
    final token = randomId(24);
    await db.doc('friendInvites/$token').set({
      'ownerId': uid,
      'name': name,
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 6, hours: 23)),
      ),
    });
    return Uri.parse(publicUrl)
        .replace(queryParameters: {'friend': token})
        .toString();
  }

  Future<void> addFriend(String invitation, String name) async {
    await requireAccount();
    final token =
        Uri.tryParse(invitation.trim())?.queryParameters['friend'] ??
        invitation.trim();
    if (!RegExp(r'^[a-f0-9]{48}$').hasMatch(token)) {
      throw const FormatException('Paste a valid friendship link.');
    }
    Json? invite;
    try {
      invite = (await db.doc('friendInvites/$token').get()).data();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'That friendship link expired or was revoked. Ask for a fresh one.',
        );
      }
      rethrow;
    }
    if (invite == null) {
      throw StateError(
        'That friendship link expired or was revoked. Ask for a fresh one.',
      );
    }
    final other = invite['ownerId'] as String;
    if (other == uid) throw StateError('Share your link with another person.');
    final members = [uid, other]..sort();
    final ref = db.doc('friendships/${members.join('__')}');
    try {
      await ref.set({
        'members': members,
        'names': {uid: name, other: invite['name']},
        'inviteId': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        try {
          if ((await ref.get()).exists) return;
        } on FirebaseException catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> revokeFriendLinks() async {
    await requireAccount();
    while (true) {
      final docs = await db
          .collection('friendInvites')
          .where('ownerId', isEqualTo: uid)
          .limit(100)
          .get();
      if (docs.docs.isEmpty) break;
      final batch = db.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> inviteFriendToPlan(PlanRoom room, Json friendship) async {
    await requireAccount();
    final friend = (friendship['members'] as List).cast<String>().firstWhere(
      (id) => id != uid,
    );
    final token = await invitationFor(room);
    final mine = (await db.doc('rooms/${room.id}/members/$uid').get()).data()!;
    final invite = (await db.doc('invites/$token').get()).data()!;
    await db.doc('users/$friend/planInvites/${room.id}_$uid').set({
      'fromId': uid,
      'fromName': mine['name'],
      'roomId': room.id,
      'title': invite['title'],
      'inviteId': token,
      'friendshipId': friendship['id'],
      'expiresAt': invite['expiresAt'],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rememberPlan(PlanRoom room, Experience data) async {
    if (room.status != 'confirmed' || room.proposal == null) return;
    final entry = historySnapshot(room, data);
    final id = '${room.id}_${room.proposal!.revision}';
    await db.runTransaction((tx) async {
      final ref = db.doc('users/$uid/history/$id');
      if ((await tx.get(ref)).exists) return;
      if ((await tx.get(db.doc('users/$uid/historyHidden/$id'))).exists) return;
      if (!room.local) {
        final fresh = (await tx.get(db.doc('rooms/${room.id}'))).data();
        if (fresh == null ||
            fresh['status'] != 'confirmed' ||
            fresh['revision'] != room.revision) {
          return;
        }
      }
      tx.set(ref, {
        ...entry,
        'rating': 0,
        'again': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateFriendName(String name) async {
    if (!hasAccount) return;
    final contacts = await db
        .collection('friendships')
        .where('members', arrayContains: uid)
        .get();
    for (final contact in contacts.docs) {
      await contact.reference.update({
        FieldPath(['names', uid]): name,
      });
    }
  }
}

Json historySnapshot(PlanRoom room, Experience data) {
  final activities = proposalActivities(room, Planner(data).catalogFor(room));
  return {
    'roomId': room.id,
    'revision': room.proposal!.revision,
    'title': room.title,
    'date': room.date,
    'activities': activities.map((a) => a.name).toList(),
    'venues': activities.map((a) => a.venue).toList(),
    'totalCost': activities.fold<int>(0, (total, a) => total + a.cost),
    'calendar': activities.isEmpty
        ? ''
        : calendarFile(room, activities.first, activities),
  };
}
