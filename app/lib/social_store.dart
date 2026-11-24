part of 'store.dart';

extension MeetPeople on MeetStore {
  Future<void> archiveConfirmedHeader(String id, Json header) async {
    if (!cloud.hasAccount ||
        header['status'] != 'confirmed' ||
        header['deleting'] == true) {
      return;
    }
    final key = '${id}_${header['revision']}';
    if (!_archiving.add(key)) return;
    try {
      final saved = await cloud.db.doc('users/${cloud.uid}/history/$key').get();
      if (saved.exists) return;
      final options = await cloud.db.collection('rooms/$id/options').get();
      final value = PlanRoom(
        id: id,
        title: header['title'] as String,
        date: header['date'] as String,
        ownerId: header['ownerId'] as String,
        members: [],
        local: false,
        status: 'confirmed',
        revision: header['revision'] as int,
        proposal: Proposal.fromJson(
          Map<String, dynamic>.from(header['proposal'] as Map),
        ),
        options: options.docs
            .map((o) => <String, dynamic>{'id': o.id, ...o.data()})
            .toList(),
      );
      await cloud.rememberPlan(value, data);
    } catch (_) {
      _archiving.remove(key);
    }
  }

  Future<void> syncLocalHistory() async {
    if (!cloud.hasAccount) return;
    for (final entry in history.where((e) => e['cloud'] != true).toList()) {
      await cloud.db.runTransaction((tx) async {
        final ref = cloud.db.doc('users/${cloud.uid}/history/${entry['id']}');
        if ((await tx.get(ref)).exists) return;
        if ((await tx.get(
          cloud.db.doc('users/${cloud.uid}/historyHidden/${entry['id']}'),
        )).exists) {
          return;
        }
        tx.set(ref, {
          for (final key in [
            'roomId',
            'revision',
            'title',
            'date',
            'activities',
            'venues',
            'totalCost',
            'calendar',
            'rating',
            'again',
          ])
            key: entry[key],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      entry['cloud'] = true;
    }
    await persistHistory();
  }

  Future<void> _watchPeople() async {
    if (!cloud.hasAccount || _friendsFeed != null) return;
    _friendsFeed = cloud.db
        .collection('friendships')
        .where('members', arrayContains: cloud.uid)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            friends
              ..clear()
              ..addAll(
                snapshot.docs.map(
                  (d) => <String, dynamic>{'id': d.id, ...d.data()},
                ),
              );
            changed();
          },
          onError: (Object _) {
            serviceNotice = 'Your people could not sync. Try reconnecting.';
            changed();
          },
        );
    _planInvitesFeed = cloud.db
        .collection('users/${cloud.uid}/planInvites')
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          planInvites
            ..clear()
            ..addAll(
              snapshot.docs.map(
                (d) => <String, dynamic>{'id': d.id, ...d.data()},
              ),
            );
          changed();
        }, onError: (Object _) {});
    _historyFeed = cloud.db
        .collection('users/${cloud.uid}/history')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
          (snapshot) {
            history.removeWhere((entry) => entry['cloud'] == true);
            history.addAll(
              snapshot.docs.map(
                (d) => <String, dynamic>{
                  'id': d.id,
                  'cloud': true,
                  ...d.data(),
                },
              ),
            );
            changed();
          },
          onError: (Object _) {
            serviceNotice = 'Your private history could not sync. Local history remains available.';
            changed();
          },
        );
  }

  Future<void> _stopPeople() async {
    await _friendsFeed?.cancel();
    _friendsFeed = null;
    await _planInvitesFeed?.cancel();
    _planInvitesFeed = null;
    await _historyFeed?.cancel();
    _historyFeed = null;
    friends.clear();
    planInvites.clear();
    history.removeWhere((entry) => entry['cloud'] == true);
    _archiving.clear();
  }

  Future<void> rememberCurrentPlan() async {
    final current = room;
    if (current == null ||
        current.id == 'sample-toronto' ||
        current.status != 'confirmed' ||
        current.proposal == null) {
      return;
    }
    if (!current.local && cloud.hasAccount) {
      await cloud.rememberPlan(current, data);
      return;
    }
    final id = '${current.id}_${current.proposal!.revision}';
    if (history.any((entry) => entry['id'] == id)) return;
    history.insert(0, {
      'id': id,
      ...historySnapshot(current, data),
      'rating': 0,
      'again': false,
    });
    await persistHistory();
    changed();
  }

  Future<void> persistHistory() => preferences.setString(
    'meet.flutter.history',
    jsonEncode(history.where((entry) => entry['cloud'] != true).toList()),
  );

  Future<void> rateHistory(Json entry, int rating, bool again) async {
    if (rating < 0 || rating > 5) {
      throw const FormatException('Choose a rating from zero to five.');
    }
    if (entry['cloud'] == true) {
      await cloud.db.doc('users/${cloud.uid}/history/${entry['id']}').update({
        'rating': rating,
        'again': again,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      entry['rating'] = rating;
      entry['again'] = again;
      await persistHistory();
      changed();
    }
  }

  Future<void> deleteHistory(Json entry) async {
    if (entry['cloud'] == true) {
      final batch = cloud.db.batch();
      batch.delete(cloud.db.doc('users/${cloud.uid}/history/${entry['id']}'));
      batch.set(
        cloud.db.doc('users/${cloud.uid}/historyHidden/${entry['id']}'),
        {'updatedAt': FieldValue.serverTimestamp()},
      );
      await batch.commit();
    } else {
      history.remove(entry);
      await persistHistory();
      changed();
    }
  }
}
