part of 'store.dart';

extension MeetFeatures on MeetStore {
  Future<void> startServices() async {
    try {
      offline = (await Connectivity().checkConnectivity()).contains(
        ConnectivityResult.none,
      );
      _network = Connectivity().onConnectivityChanged.listen((result) {
        final wasOffline = offline;
        offline = result.contains(ConnectivityResult.none);
        if (wasOffline && !offline) unawaited(restoreLive());
        changed();
      });
    } catch (_) {
      /* Connectivity is advisory; SDK errors remain visible. */
    }
    await restoreLive();
    changed();
  }

  void openPendingRoom() {
    final target = liveRooms.where((r) => r.id == pendingRoomId).firstOrNull;
    if (target == null) return;
    pendingRoomId = null;
    unawaited(
      openRoom(target).catchError((Object error) {
        serviceNotice = friendlyError(error);
        changed();
      }),
    );
  }

  Future<void> _watchLivePlans() async {
    if (!cloud.connected) return;
    if (_liveList != null) return;
    await cloud.connect();
    _liveList = cloud.db
        .collection('rooms')
        .where('memberIds', arrayContains: cloud.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (snapshot) {
            liveFromCache = snapshot.metadata.isFromCache;
            final ids = snapshot.docs.map((d) => d.id).toSet();
            for (final id
                in _eventFeeds.keys.where((id) => !ids.contains(id)).toList()) {
              _eventFeeds.remove(id)?.cancel();
              activityFeed.removeWhere((event) => event['roomId'] == id);
            }
            liveRooms
              ..clear()
              ..addAll(
                snapshot.docs.map((d) {
                  final h = d.data();
                  return PlanRoom(
                    id: d.id,
                    title: h['title'] as String,
                    date: h['date'] as String,
                    ownerId: h['ownerId'] as String,
                    members: [],
                    local: false,
                    status: h['status'] as String,
                    revision: h['revision'] as int,
                    inviteId: h['lastJoinInviteId'] as String?,
                  );
                }),
              );
            for (final value in liveRooms) {
              _eventFeeds.putIfAbsent(
                value.id,
                () => cloud.db
                    .collection('rooms/${value.id}/events')
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots()
                    .listen((events) {
                      activityFeed.removeWhere((e) => e['roomId'] == value.id);
                      activityFeed.addAll(
                        events.docs.map(
                          (d) => <String, dynamic>{
                            'id': d.id,
                            'roomId': value.id,
                            'title': value.title,
                            ...d.data(),
                          },
                        ),
                      );
                      activityFeed.sort(
                        (a, b) =>
                            ((b['createdAt'] as Timestamp?)
                                        ?.millisecondsSinceEpoch ??
                                    0)
                                .compareTo(
                                  (a['createdAt'] as Timestamp?)
                                          ?.millisecondsSinceEpoch ??
                                      0,
                                ),
                      );
                      changed();
                    }, onError: (Object _) {}),
              );
            }
            for (final header in snapshot.docs) {
              unawaited(archiveConfirmedHeader(header.id, header.data()));
            }
            if (room?.local == false && !ids.contains(room!.id)) {
              _subscription?.cancel();
              room = null;
              tab = 'plans';
              serviceNotice =
                  'This plan was deleted, or you are no longer a member.';
            }
            changed();
            openPendingRoom();
          },
          onError: (Object error) {
            serviceNotice = friendlyError(error);
            changed();
          },
        );
    if (cloud.hasAccount) {
      _profile = cloud.db
          .doc('users/${cloud.uid}')
          .snapshots()
          .listen(
            (snapshot) {
              final profile = snapshot.data();
              if (profile == null) return;
              try {
                final card = PreferenceCard.fromJson(
                  Map<String, dynamic>.from(profile['card'] as Map),
                )..validate(data);
                defaultCard = card;
                name = profile['name'] as String;
                unawaited(
                  preferences.setString(
                    'meet.flutter.card',
                    jsonEncode(card.toJson()),
                  ),
                );
                unawaited(preferences.setString('meet.flutter.name', name));
                changed();
              } catch (_) {
                /* A bad profile must not prevent local planning. */
              }
            },
            onError: (Object _) {
              serviceNotice = 'Your saved account preferences could not sync. Local controls remain available.';
              changed();
            },
          );
    }
    notifications.onOpenRoom = (id) {
      pendingRoomId = id;
      tab = 'updates';
      openPendingRoom();
      changed();
    };
    unawaited(notifications.restore());
    await _watchPeople();
  }

  Future<void> _stopAccountFeeds() async {
    await _stopPeople();
    await _subscription?.cancel();
    _subscription = null;
    await _liveList?.cancel();
    _liveList = null;
    await _profile?.cancel();
    _profile = null;
    for (final feed in _eventFeeds.values) {
      await feed.cancel();
    }
    _eventFeeds.clear();
    activityFeed.clear();
    room = null;
    liveRooms.clear();
  }

  Future<void> register(String email, String password) async {
    await cloud.registerAccount(email, password);
    await cloud.saveProfile(name, defaultCard!);
    await preferences.setBool('meet.flutter.live', true);
    await _stopAccountFeeds();
    await syncLocalHistory();
    await refreshLive();
    changed();
  }

  Future<void> signIn(String email, String password) async {
    await cloud.connect();
    await notifications.disable();
    await _stopAccountFeeds();
    try {
      await cloud.signInAccount(email, password);
      await syncLocalHistory();
      await preferences.setBool('meet.flutter.live', true);
      await refreshLive();
    } catch (_) {
      await restoreLive();
      rethrow;
    }
    changed();
  }

  Future<void> signOut() async {
    await notifications.disable();
    await _stopAccountFeeds();
    await cloud.signOutAccount();
    defaultCard = data.defaultCard;
    name = 'You';
    await preferences.remove('meet.flutter.card');
    await preferences.remove('meet.flutter.name');
    await preferences.remove('meet.flutter.live');
    receipts.clear();
    explanations.clear();
    tab = 'account';
    changed();
  }

  void _hostRequired() {
    if (room == null || !isHost) throw StateError('Only the host can do that.');
  }

  Future<void> editPlan(String title, String date) async {
    _hostRequired();
    title = title.trim();
    final parsed = DateTime.tryParse(date);
    final now = DateTime.now();
    if (title.isEmpty ||
        title.length > 70 ||
        parsed == null ||
        isoDate(parsed) != date ||
        parsed.isBefore(DateTime(now.year, now.month, now.day))) {
      throw const FormatException(
        'Add a title and choose today or a later date.',
      );
    }
    final current = room!;
    if (current.local) {
      current.title = title;
      current.date = date;
      _reset(current, 'The plan changed');
      await persist();
      changed();
    } else {
      await cloud.editPlan(current, title, date);
    }
  }

  Future<void> rename(String displayName) async {
    displayName = displayName.trim();
    if (displayName.isEmpty || displayName.length > 30) {
      throw const FormatException('Use a name from 1 to 30 characters.');
    }
    final current = room;
    if (current != null && me != null) {
      if (current.local) {
        me!.name = displayName;
        _reset(current, 'A name changed');
        await persist();
      } else {
        await cloud.renameMember(current, displayName);
      }
    }
    name = displayName;
    await preferences.setString('meet.flutter.name', name);
    if (cloud.hasAccount) await cloud.saveProfile(name, defaultCard!);
    if (cloud.hasAccount) await cloud.updateFriendName(name);
    changed();
  }

  Future<void> updateOption(String id, Json? option) async {
    _hostRequired();
    if (option != null) data.validateOption(option);
    final current = room!;
    if (current.local) {
      final index = current.options.indexWhere((o) => o['id'] == id);
      if (index < 0) {
        throw StateError('That activity is no longer in this plan.');
      }
      if (option == null) {
        current.options.removeAt(index);
      } else {
        current.options[index] = {'id': id, ...option};
      }
      _reset(current, 'An idea changed');
      explanations.clear();
      await persist();
      changed();
    } else {
      await cloud.editOption(current, id, option);
    }
  }

  Future<void> transfer(String uid) async {
    _hostRequired();
    final current = room!;
    if (!current.members.any((m) => m.id == uid) || uid == current.ownerId) {
      throw StateError('Choose another current member.');
    }
    if (current.local) {
      current.ownerId = uid;
      _reset(current, 'The host changed');
      await persist();
      changed();
    } else {
      await cloud.transferHost(current, uid);
    }
  }

  Future<void> removePerson(String id) async {
    final current = room!;
    if (!isHost && id != myId) {
      throw StateError('Only the host can remove another person.');
    }
    if (id == current.ownerId) {
      throw StateError('Transfer hosting or delete the plan before leaving.');
    }
    final leaving = id == myId;
    if (current.local) {
      current.members.removeWhere((p) => p.id == id);
      _reset(current, 'A person left');
      await persist();
      if (leaving) {
        navigate('plans');
      } else {
        changed();
      }
    } else {
      await cloud.removeMember(current, id);
      if (leaving) {
        navigate('plans');
        await refreshLive();
      }
    }
  }

  Future<void> deleteCurrentPlan() async {
    _hostRequired();
    final current = room!;
    if (current.local) {
      localRooms.removeWhere((r) => r.id == current.id);
      if (current.id == 'sample-toronto') localRooms.add(_sample());
      await persist();
    } else {
      await cloud.deletePlan(current);
      await refreshLive();
    }
    navigate('plans');
  }

  Future<void> proposeItinerary(List<Activity> activities) async {
    _hostRequired();
    final current = room!;
    if (current.status == 'confirmed') {
      throw StateError(
        'Reopen the plan before replacing a confirmed decision.',
      );
    }
    final plan = planner.itinerary(activities, current.members);
    if (!plan.eligible) throw StateError(plan.reasons.join(' '));
    final first = planner.evaluate(activities.first, current.members);
    if (current.local) {
      current.revision++;
      current.proposal = Proposal(
        activities.first.id,
        plan.stops.first['startMinute'] as int,
        current.revision,
        stops: plan.stops,
      );
      current.votes.clear();
      current.status = 'voting';
      reopenedNotice = null;
      await persist();
      changed();
    } else {
      await cloud.propose(current, first, stops: plan.stops);
    }
  }
}
