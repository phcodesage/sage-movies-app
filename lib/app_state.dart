import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagemovies/models/movie.dart';

class AppState extends ChangeNotifier {
  final Map<String, Movie> _myListMap = <String, Movie>{};

  // Watched TV episodes, keyed as `${tvId}:S${season}E${episode}` — the same scheme the
  // web app uses in localStorage, so the concept stays consistent across platforms even
  // though the two stores never sync.
  final Set<String> _watchedEpisodes = <String>{};
  static const String _watchedPrefsKey = 'watched_episodes_v1';

  AppState() {
    _load();
    _loadWatched();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString('my_list_movies_v2');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(jsonStr);
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _myListMap[key] = Movie.fromJson(value);
          }
        });
      } else {
        // Migration from legacy list of IDs if available
        final List<String>? legacyIds = prefs.getStringList('my_list_ids');
        if (legacyIds != null) {
          for (final id in legacyIds) {
            _myListMap[id] = Movie(
              id: id,
              title: 'Saved Movie #$id',
              posterUrl: '',
              backdropUrl: '',
              overview: '',
              rating: 0.0,
            );
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading my list: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> jsonMap = {};
      _myListMap.forEach((key, movie) {
        jsonMap[key] = movie.toJson();
      });
      await prefs.setString('my_list_movies_v2', json.encode(jsonMap));
      await prefs.setStringList('my_list_ids', _myListMap.keys.toList());
    } catch (e) {
      debugPrint('Error saving my list: $e');
    }
  }

  // --- Watched episodes --------------------------------------------------

  static String _episodeKey(String tvId, int season, int episode) =>
      '$tvId:S${season}E$episode';

  Future<void> _loadWatched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? keys = prefs.getStringList(_watchedPrefsKey);
      if (keys != null) {
        _watchedEpisodes
          ..clear()
          ..addAll(keys);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading watched episodes: $e');
    }
  }

  Future<void> _saveWatched() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchedPrefsKey, _watchedEpisodes.toList());
    } catch (e) {
      debugPrint('Error saving watched episodes: $e');
    }
  }

  bool isEpisodeWatched(String tvId, int season, int episode) =>
      _watchedEpisodes.contains(_episodeKey(tvId, season, episode));

  /// Idempotent — safe to call on every play without churning state or storage.
  void markEpisodeWatched(String tvId, int season, int episode) {
    if (_watchedEpisodes.add(_episodeKey(tvId, season, episode))) {
      notifyListeners();
      _saveWatched();
    }
  }

  void toggleEpisodeWatched(String tvId, int season, int episode) {
    final key = _episodeKey(tvId, season, episode);
    if (!_watchedEpisodes.remove(key)) {
      _watchedEpisodes.add(key);
    }
    notifyListeners();
    _saveWatched();
  }

  bool isInMyList(String id) => _myListMap.containsKey(id);

  Set<String> get myListIds => Set.unmodifiable(_myListMap.keys.toSet());

  List<Movie> get myList => _myListMap.values.toList();

  bool toggleMyList(Movie movie) {
    final added = !_myListMap.containsKey(movie.id);
    if (added) {
      _myListMap[movie.id] = movie;
    } else {
      _myListMap.remove(movie.id);
    }
    notifyListeners();
    _save();
    return added;
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  AppStateProvider({super.key, required super.child})
      : super(notifier: AppState());

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in context');
    return provider!.notifier!;
  }

  static AppState read(BuildContext context) {
    final provider =
        context.getInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in context');
    return provider!.notifier!;
  }
}
