import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sagemovies/data/studio_catalog.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/services/api_service.dart';

/// Resolves a title to a branded studio.
///
/// The list endpoints carry no studio data at all, so every resolution costs one
/// `/api/movie/{id}` call. A horizontally-scrolling row would otherwise fire
/// dozens at once, hence the debounce + in-flight dedupe + concurrency cap here.
///
/// Keeps its own SharedPreferences cache rather than using
/// [PreloadService.getCollection], which only rehydrates four hardcoded keys and
/// would silently miss on every cold start.
class StudioService {
  StudioService._();

  static const String _prefsKey = 'studio_map_v1';
  static const String _unresolved = '';
  static const int _maxConcurrent = 3;
  static const Duration _debounce = Duration(milliseconds: 250);
  static const Duration _flushInterval = Duration(seconds: 2);

  /// id -> studio key, or [_unresolved] meaning "we looked and found nothing".
  /// Distinct from an absent entry, which means "not tried yet".
  static final Map<String, String> _memo = {};
  static final Map<String, Future<String?>> _inFlight = {};
  static final Map<String, Timer> _debounceTimers = {};

  /// One gate per key, shared by every caller waiting on it. Cancelling a
  /// timer must never strand a caller, so the timer restarts but the gate
  /// stays the same object.
  static final Map<String, Completer<void>> _debounceGates = {};

  static final Queue<Completer<void>> _waiting = Queue<Completer<void>>();
  static int _active = 0;

  static Timer? _flushTimer;
  static bool _dirty = false;
  static bool _initialized = false;

  /// Bumped on every new resolution so badges can rebuild without their parent
  /// row rebuilding.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        decoded.forEach((k, v) => _memo[k] = v as String);
      }
    } catch (e) {
      debugPrint('[StudioService] cache load failed: $e');
    }
  }

  static String _cacheKey(String mediaType, String id) => '$mediaType:$id';

  /// Cached answer, if we already have one. Never triggers a request.
  static StudioEntry? peek(Movie movie) {
    final key = _memo[_cacheKey(_type(movie), movie.id)];
    if (key == null || key == _unresolved) return null;
    return StudioCatalog.byKey(key);
  }

  static bool isResolved(Movie movie) =>
      _memo.containsKey(_cacheKey(_type(movie), movie.id));

  static String _type(Movie movie) => movie.mediaType == 'tv' ? 'tv' : 'movie';

  /// Resolve [movie]'s studio, debounced so tiles flung past never enqueue.
  static Future<StudioEntry?> resolve(Movie movie) async {
    final type = _type(movie);
    final key = _cacheKey(type, movie.id);

    final cached = _memo[key];
    if (cached != null) {
      return cached == _unresolved ? null : StudioCatalog.byKey(cached);
    }

    await _awaitDebounce(key);

    // Something else may have resolved it while we waited.
    final settled = _memo[key];
    if (settled != null) {
      return settled == _unresolved ? null : StudioCatalog.byKey(settled);
    }

    final pending = _inFlight[key];
    if (pending != null) return StudioCatalog.byKey(await pending);

    final future = _fetch(type, movie.id, key);
    _inFlight[key] = future;
    try {
      return StudioCatalog.byKey(await future);
    } finally {
      _inFlight.remove(key);
    }
  }

  static Future<void> _awaitDebounce(String key) {
    _debounceTimers[key]?.cancel();
    final gate = _debounceGates[key] ?? Completer<void>();
    _debounceGates[key] = gate;
    _debounceTimers[key] = Timer(_debounce, () {
      _debounceTimers.remove(key);
      _debounceGates.remove(key);
      if (!gate.isCompleted) gate.complete();
    });
    return gate.future;
  }

  static Future<String?> _fetch(String type, String id, String key) async {
    await _acquire();
    try {
      final details = await ApiService.fetchFullDetails(type, id);
      final entry = details == null ? null : resolveFromDetails(details, mediaType: type);
      _memo[key] = entry?.key ?? _unresolved;
      _scheduleFlush();
      if (entry != null) revision.value++;
      return entry?.key;
    } catch (e) {
      debugPrint('[StudioService] resolve failed for $key: $e');
      return null;
    } finally {
      _release();
    }
  }

  /// Pick the studio out of a full-details payload.
  ///
  /// For TV, `networks[0]` is the recognizable answer — House of the Dragon's
  /// first production company is "Revolution Sun Studios", with HBO buried at
  /// index 5. For film, scan every company and prefer a registered studio;
  /// falling back to `production_companies[0]` would surface arbitrary
  /// financiers like "Fox 2000 Pictures".
  static StudioEntry? resolveFromDetails(
    Map<String, dynamic> details, {
    String mediaType = 'movie',
  }) {
    if (mediaType == 'tv') {
      final networks = details['networks'] as List?;
      if (networks != null && networks.isNotEmpty) {
        final first = networks.first as Map<String, dynamic>;
        final byId = StudioCatalog.matchByNetworkId(first['id'] as int?);
        if (byId != null) return byId;
        final byName = StudioCatalog.matchByName(first['name'] as String?);
        if (byName != null) return byName;
      }
    }

    final comps = details['production_companies'] as List?;
    if (comps != null) {
      for (final c in comps) {
        final match = StudioCatalog.matchByName((c as Map)['name'] as String?);
        if (match != null) return match;
      }
    }

    // Networks are still a decent signal for a film-typed title that is really a
    // streaming original.
    final networks = details['networks'] as List?;
    if (networks != null) {
      for (final n in networks) {
        final match = StudioCatalog.matchByNetworkId((n as Map)['id'] as int?) ??
            StudioCatalog.matchByName(n['name'] as String?);
        if (match != null) return match;
      }
    }

    return null;
  }

  static Future<void> _acquire() {
    if (_active < _maxConcurrent) {
      _active++;
      return Future.value();
    }
    final c = Completer<void>();
    _waiting.add(c);
    return c.future;
  }

  static void _release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeFirst().complete();
    } else {
      _active--;
    }
  }

  static void _scheduleFlush() {
    _dirty = true;
    _flushTimer ??= Timer(_flushInterval, () {
      _flushTimer = null;
      if (_dirty) _flush();
    });
  }

  static Future<void> _flush() async {
    _dirty = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json.encode(_memo));
    } catch (e) {
      debugPrint('[StudioService] cache save failed: $e');
    }
  }
}
