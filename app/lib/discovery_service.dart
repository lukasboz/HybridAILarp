import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'domain.dart';

const providerContact = 'https://github.com/lukasboz/HybridAILarp';

class Venue {
  Venue(this.json);
  final Json json;
  String get name => json['name'] as String;
  String get sourceUrl => json['sourceUrl'] as String;
  Json get sourceFacts => {
    for (final entry in {
      'hours': json['openingHours'],
      'fee': json['fee'],
      'access': json['access'],
    }.entries)
      entry.key: '${entry.value ?? 'Not provided'}'.substring(
        0,
        '${entry.value ?? 'Not provided'}'.length.clamp(0, 300),
      ),
  };
}

/// Free, user-triggered OSM searches. Missing prices/access are never fabricated.
class DiscoveryService {
  DiscoveryService(this.preferences);
  final SharedPreferences preferences;
  DateTime? _lastSearch;
  DateTime? _lastRoute;
  Future<void> _routeQueue = Future<void>.value();
  final _inFlight = <String, Future<RouteResult>>{};

  // Respect the community endpoint's capacity, including simultaneous callers.
  Future<void> _routeSlot() {
    final next = _routeQueue.then((_) async {
      final elapsed = _lastRoute == null
          ? 3200
          : DateTime.now().difference(_lastRoute!).inMilliseconds;
      if (elapsed < 3200) {
        await Future<void>.delayed(Duration(milliseconds: 3200 - elapsed));
      }
      final day = DateTime.now().toUtc().toIso8601String().substring(0, 10);
      final key = 'meet.routeBudget.$day';
      final used = preferences.getInt(key) ?? 0;
      if (used >= 100) {
        throw StateError(
          'Today’s community route allowance is used. Saved routes and estimated travel remain available.',
        );
      }
      for (final old in preferences.getKeys().where(
        (k) => k.startsWith('meet.routeBudget.') && k != key,
      )) {
        await preferences.remove(old);
      }
      await preferences.setInt(key, used + 1);
      _lastRoute = DateTime.now();
    });
    _routeQueue = next.catchError((Object _) {});
    return next;
  }

  static const _filters = {
    'coffee': '[amenity=cafe]',
    'food': '[amenity~"restaurant|food_court|marketplace"]',
    'art': '[tourism~"museum|gallery"]',
    'outdoors': '[leisure~"park|garden"]',
    'games': '[leisure~"bowling_alley|amusement_arcade|sports_centre"]',
    'music': '[amenity~"theatre|arts_centre"]',
  };
  Map<String, String> get headers => {
    'Accept': 'application/json',
    if (!kIsWeb) 'User-Agent': 'MeetHalfway/0.4 ($providerContact)',
  };

  Future<List<Venue>> search(
    Json area,
    String interest, {
    bool refresh = false,
  }) async {
    final filter = _filters[interest];
    if (filter == null) throw const FormatException('Choose an interest.');
    final key = 'meet.discovery.${area["id"]}.$interest';
    final cached = preferences.getString(key);
    if (!refresh && cached != null) {
      try {
        final value = jsonDecode(cached) as Json;
        if (DateTime.now()
                .difference(DateTime.parse(value['at'] as String))
                .inHours <
            24) {
          return (value['venues'] as List)
              .map((v) => Venue(Map<String, dynamic>.from(v as Map)))
              .toList();
        }
      } catch (_) {
        /* Discard an invalid or outdated cache. */
      }
    }
    if (_lastSearch != null &&
        DateTime.now().difference(_lastSearch!).inSeconds < 5) {
      throw StateError('Wait a few seconds before another place search.');
    }
    _lastSearch = DateTime.now();
    final client = http.Client();
    try {
      final response = await client
          .post(
            Uri.https('overpass-api.de', '/api/interpreter'),
            headers: headers,
            body: {
              'data':
                  '[out:json][timeout:20];nwr(around:3500,${area["lat"]},${area["lng"]})$filter["name"];out center tags 35;',
            },
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200 || response.bodyBytes.length > 1500000) {
        throw StateError(
          'Place search is busy. Try again later or add an idea yourself.',
        );
      }
      final data = jsonDecode(response.body) as Json;
      final at = DateTime.now().toUtc().toIso8601String();
      final venues = <Venue>[];
      for (final element in (data['elements'] as List? ?? []).take(35)) {
        final e = Map<String, dynamic>.from(element as Map);
        final tags = Map<String, dynamic>.from(e['tags'] as Map? ?? {});
        final center = e['center'] as Map? ?? e;
        final lat = center['lat'], lng = center['lon'];
        if (tags['name'] is! String || lat is! num || lng is! num) continue;
        final source = 'https://www.openstreetmap.org/${e["type"]}/${e["id"]}';
        venues.add(
          Venue({
            'name': (tags['name'] as String).substring(
              0,
              (tags['name'] as String).length.clamp(0, 70),
            ),
            'venue': tags['name'],
            'areaId': area['id'],
            'lat': lat,
            'lng': lng,
            'interest': interest,
            'sourceUrl': source,
            'retrievedAt': at,
            'openingHours': tags['opening_hours'] ?? 'Not provided',
            'fee': tags['charge'] ?? tags['fee'] ?? 'Not provided',
            'access': tags['wheelchair'] ?? 'Not provided',
            'website': tags['website'] ?? '',
            'address': [
              tags['addr:housenumber'],
              tags['addr:street'],
            ].whereType<String>().join(' '),
          }),
        );
      }
      await preferences.setString(
        key,
        jsonEncode({'at': at, 'venues': venues.map((v) => v.json).toList()}),
      );
      return venues;
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError(
        'Couldn’t reach place search. Saved results and manual ideas are still available.',
      );
    } finally {
      client.close();
    }
  }

  Future<RouteResult> route({
    required double fromLat,
    required double fromLng,
    required Activity to,
    required String mode,
    required DateTime departure,
    bool stepFree = false,
  }) async {
    final roundedDeparture = departure.toUtc().toIso8601String().substring(
      0,
      16,
    );
    final key =
        'meet.route.$fromLat.$fromLng.${to.lat}.${to.lng}.$mode.$stepFree.$roundedDeparture';
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final request = _routeRequest(
      key,
      fromLat: fromLat,
      fromLng: fromLng,
      to: to,
      mode: mode,
      departure: departure,
      stepFree: stepFree,
    );
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      _inFlight.remove(key);
    }
  }

  Future<RouteResult> _routeRequest(
    String key, {
    required double fromLat,
    required double fromLng,
    required Activity to,
    required String mode,
    required DateTime departure,
    required bool stepFree,
  }) async {
    final cached = preferences.getString(key);
    if (cached != null) {
      try {
        final result = RouteResult.fromJson(jsonDecode(cached) as Json);
        final age = DateTime.now().toUtc().difference(
          DateTime.parse(result.fetchedAt),
        );
        if (!age.isNegative &&
            age < const Duration(minutes: 15) &&
            result.minutes >= 0 &&
            result.minutes <= 300) {
          return result;
        }
      } catch (_) {
        /* Refresh invalid cache. */
      }
    }
    await _routeSlot();
    final client = http.Client();
    try {
      final response = await client
          .get(
            Uri.https('api.transitous.org', '/api/v6/plan', {
              'fromPlace': '$fromLat,$fromLng',
              'toPlace': '${to.lat},${to.lng}',
              'time': departure.toUtc().toIso8601String(),
              'numItineraries': '1',
              'arriveBy': 'true',
              'directModes': mode == 'bike' ? 'BIKE' : 'WALK',
              'transitModes': mode == 'transit' ? 'TRANSIT' : '',
              if (stepFree) 'pedestrianProfile': 'WHEELCHAIR',
            }),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200 || response.bodyBytes.length > 1000000) {
        throw const FormatException();
      }
      final data = jsonDecode(response.body) as Json;
      final choices = [
        ...(data['itineraries'] as List? ?? []),
        ...(data['direct'] as List? ?? []),
      ];
      if (choices.isEmpty) throw const FormatException();
      final candidates =
          choices
              .map((v) => Map<String, dynamic>.from(v as Map))
              .where(
                (v) =>
                    v['duration'] is num &&
                    (v['duration'] as num).isFinite &&
                    (v['duration'] as num) >= 0 &&
                    (v['duration'] as num) <= 18000,
              )
              .toList()
            ..sort(
              (a, b) => (a['duration'] as num).compareTo(b['duration'] as num),
            );
      if (candidates.isEmpty) throw const FormatException();
      final best = candidates.first;
      final result = RouteResult(
        ((best['duration'] as num) / 60).ceil(),
        (best['legs'] as List? ?? []).map((v) {
          final leg = v as Map;
          return [
            leg['mode'],
            leg['routeShortName'],
            (leg['from'] as Map?)?['name'],
            (leg['to'] as Map?)?['name'],
          ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
        }).toList(),
        DateTime.now().toUtc().toIso8601String(),
      );
      final keys = preferences
          .getKeys()
          .where((k) => k.startsWith('meet.route.'))
          .toList();
      if (keys.length >= 200) {
        // Entries older than fifteen minutes have no planning value.
        for (final old in keys) {
          try {
            final saved = RouteResult.fromJson(
              jsonDecode(preferences.getString(old)!) as Json,
            );
            if (DateTime.now().toUtc().difference(
                  DateTime.parse(saved.fetchedAt),
                ) <
                const Duration(minutes: 15)) {
              continue;
            }
          } catch (_) {}
          await preferences.remove(old);
        }
      }
      await preferences.setString(key, jsonEncode(result.toJson()));
      return result;
    } catch (_) {
      throw StateError(
        'No sourced route is available for this trip right now. The planner still shows its labelled neighbourhood estimate.',
      );
    } finally {
      client.close();
    }
  }
}

class RouteResult {
  RouteResult(this.minutes, this.legs, this.fetchedAt);
  final int minutes;
  final List<String> legs;
  final String fetchedAt;
  factory RouteResult.fromJson(Json v) => RouteResult(
    v['minutes'] as int,
    List<String>.from(v['legs'] as List),
    v['fetchedAt'] as String,
  );
  Json toJson() => {'minutes': minutes, 'legs': legs, 'fetchedAt': fetchedAt};
}
