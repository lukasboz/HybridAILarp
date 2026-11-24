part of 'store.dart';

extension RoutedPlanning on MeetStore {
  void cancelRouting() {
    _routingGeneration++;
  }

  Future<void> useEstimatedTravel() async {
    _hostRequired();
    final current = room!;
    if (current.local) {
      current.travelSource = 'estimate';
      _reset(current, 'The travel source changed');
      await persist();
    } else {
      await cloud.db.doc('rooms/${current.id}').update({
        'travelSource': 'estimate',
        'revision': FieldValue.increment(1),
        'status': 'gathering',
        'proposal': null,
      });
    }
    changed();
  }

  Future<void> refreshRoutedTravel({List<Activity>? itinerary}) async {
    _hostRequired();
    if (routingBusy) throw StateError('A route update is already running.');
    final current = room!;
    if (!current.allReady || current.members.length < 2) {
      throw StateError(
        'Everyone must share preferences before checking group routes.',
      );
    }
    final startRevision = current.revision;
    final basis = planningBasis(current, data);
    final generation = ++_routingGeneration;
    routingBusy = true;
    routingProgress = 0;
    changed();
    final facts = <String, Json>{};
    final estimate = Planner(data);
    void check() {
      if (generation != _routingGeneration) {
        throw StateError('Route update cancelled.');
      }
      if (room?.id != current.id ||
          room!.revision != startRevision ||
          planningBasis(room!, data) != basis) {
        throw StateError(
          'The group changed. The route update was discarded; check the new preferences.',
        );
      }
    }

    Future<void> fetch(
      Activity destination,
      int arrival, {
      Activity? from,
    }) async {
      check();
      final minutes = <String, dynamic>{};
      var oldest = DateTime.now().millisecondsSinceEpoch;
      final people = current.members;
      // Three in flight at most; requests are cached and start only after a
      // disclosure. No names or notes are sent to the routing provider.
      for (var offset = 0; offset < people.length; offset += 3) {
        await Future.wait(
          people.skip(offset).take(3).map((person) async {
            final card = person.card!;
            final area = data.areas.firstWhere((a) => a['id'] == card.areaId);
            try {
              final result = await discovery.route(
                fromLat: from?.lat ?? (area['lat'] as num).toDouble(),
                fromLng: from?.lng ?? (area['lng'] as num).toDouble(),
                to: destination,
                mode: card.mode,
                stepFree: card.stepFree,
                departure: torontoInstant(current.date, arrival),
              );
              minutes[person.id] = result.minutes <= 300
                  ? result.minutes
                  : null;
              final at = DateTime.parse(result.fetchedAt)
                  .millisecondsSinceEpoch;
              if (at < oldest) oldest = at;
            } catch (_) {
              minutes[person.id] = null;
            }
          }),
        );
        check();
      }
      facts['${from?.id ?? 'start'}__${destination.id}'] = {
        'basis': basis,
        'fromId': from?.id ?? '',
        'candidateId': destination.id,
        'arrivalMinute': arrival,
        'minutes': minutes,
        'provider': 'Transitous',
        'checkedAt': oldest,
        'expiresAt': oldest + const Duration(minutes: 15).inMilliseconds,
      };
    }

    try {
      final catalog =
          itinerary ??
          estimate.catalogFor(current).where((a) {
            final evaluated = estimate.evaluate(a, current.members);
            return evaluated.start != null &&
                evaluated.reasons.every(
                  (r) => r == 'Beyond someone’s travel limit.',
                );
          }).toList();
      if (catalog.isEmpty) {
        throw StateError(
          'No activities meet the group’s non-travel limits. Review those preferences first.',
        );
      }
      for (final (i, activity) in catalog.indexed) {
        final evaluated = estimate.evaluate(activity, current.members);
        if (evaluated.start == null) continue;
        await fetch(activity, evaluated.start!);
        routingProgress =
            (i + 1) / (catalog.length + (itinerary == null ? 0 : 6));
        changed();
      }
      if (itinerary != null) {
        final seed = estimate.itinerary(itinerary, current.members);
        if (seed.stops.length != itinerary.length) {
          throw StateError(
            'Choose stops with a feasible shared time window first.',
          );
        }
        var schedule = seed.stops;
        var converged = false;
        for (var attempt = 0; attempt < 3; attempt++) {
          for (var i = 1; i < itinerary.length; i++) {
            await fetch(
              itinerary[i],
              schedule[i]['startMinute'] as int,
              from: itinerary[i - 1],
            );
          }
          final preview = PlanRoom(
            id: current.id,
            title: current.title,
            date: current.date,
            ownerId: current.ownerId,
            members: current.members,
            options: current.options,
            routes: {...current.routes, ...facts},
            travelSource: 'routed',
          );
          final candidate = Planner(
            data,
            room: preview,
          ).itinerary(itinerary, current.members);
          if (candidate.stops.length != itinerary.length) {
            throw StateError(
              'Sourced travel leaves too little time for these stops. Choose a wider window or closer places.',
            );
          }
          converged = candidate.stops.indexed.every(
            (s) => s.$2['startMinute'] == schedule[s.$1]['startMinute'],
          );
          schedule = candidate.stops;
          if (converged) break;
        }
        if (!converged) {
          throw StateError(
            'Transit times changed the itinerary’s timing repeatedly. Adjust the stops or time window and try again.',
          );
        }
      }
      check();
      final available = facts.values.any(
        (f) => (f['minutes'] as Map).values.every((v) => v is int),
      );
      if (!available) {
        throw StateError(
          'No complete group routes were available. The previous travel source was kept.',
        );
      }
      if (facts.values.any(
        (f) => (f['expiresAt'] as int) <= DateTime.now().millisecondsSinceEpoch,
      )) {
        throw StateError(
          'The earliest routes expired while the update was running. Try a smaller set of activities.',
        );
      }
      if (current.local) {
        current.routes.addAll(facts);
        current.travelSource = 'routed';
        _reset(current, 'Sourced travel times changed');
        await persist();
      } else {
        await cloud.db.runTransaction((tx) async {
          final ref = cloud.db.doc('rooms/${current.id}');
          final header = (await tx.get(ref)).data()!;
          if (header['revision'] != startRevision) {
            throw StateError('The plan changed. Refresh routes again.');
          }
          for (final entry in facts.entries) {
            tx.set(ref.collection('routes').doc(entry.key), {
              ...entry.value,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          tx.update(ref, {
            'travelSource': 'routed',
            'revision': startRevision + 1,
            'proposal': null,
            'status': 'gathering',
          });
        });
        await cloud.recordActivity(current.id, 'plan', startRevision + 1);
      }
      explanations.clear();
      routingProgress = 1;
      changed();
    } finally {
      routingBusy = false;
      changed();
    }
  }
}
