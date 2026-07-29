import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagemovies/models/movie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PreloadService {
  static const String _keyTrendingMovies = 'cached_trending_movies_v2';
  static const String _keyActionMovies = 'cached_action_movies_v2';
  static const String _keyTrendingTv = 'cached_trending_tv_v2';
  static const String _keyAnimeCollection = 'cached_anime_collection_v2';

  static final Map<String, List<Movie>> _cache = {};
  static bool _initialized = false;

  /// Default seed dataset so app opens IMMEDIATELY on clean install with 0 internet lag.
  static final List<Movie> _seedTrendingMovies = [
    Movie(
      id: '693134',
      title: 'Dune: Part Two',
      posterUrl: '/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
      backdropUrl: '/xOMo8BRK7PfcJv9JCnx7s52SuY.jpg',
      overview: 'Follow the mythic journey of Paul Atreides as he unites with Chani and the Fremen while on a warpath of revenge against the conspirators who destroyed his family.',
      rating: 8.3,
      mediaType: 'movie',
    ),
    Movie(
      id: '533535',
      title: 'Deadpool & Wolverine',
      posterUrl: '/8cdWjvZwcExd22dEwUdE2v2qvi.jpg',
      backdropUrl: '/yDHYTfA3R0jFYba16jBB1ef8oIt.jpg',
      overview: 'A listless Wade Wilson toils away in civilian life with his days as the morally flexible mercenary Deadpool behind him.',
      rating: 7.7,
      mediaType: 'movie',
    ),
    Movie(
      id: '1022789',
      title: 'Inside Out 2',
      posterUrl: '/vpnVM9B6NMmQpEZZ08KHxYyE9m.jpg',
      backdropUrl: '/p2fRZBxYvLE9vE2a9jBB1ef8oIt.jpg',
      overview: 'Teenager Rileys mind headquarters is undergoing a sudden demolition to make room for something entirely unexpected: new Emotions!',
      rating: 7.6,
      mediaType: 'movie',
    ),
    Movie(
      id: '823464',
      title: 'Godzilla x Kong: The New Empire',
      posterUrl: '/z1y5ebScV28w92E3v1f855e9m.jpg',
      backdropUrl: '/x22v92E3v1f855e9m.jpg',
      overview: 'An all-new adventure that pits the almighty Kong and the fearsome Godzilla against a colossal undiscovered threat hidden within our world.',
      rating: 7.2,
      mediaType: 'movie',
    ),
    Movie(
      id: '872585',
      title: 'Oppenheimer',
      posterUrl: '/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
      backdropUrl: '/fm6KqXrm23v92E3v1f855e9m.jpg',
      overview: 'The story of J. Robert Oppenheimers role in the development of the atomic bomb during World War II.',
      rating: 8.1,
      mediaType: 'movie',
    ),
    Movie(
      id: '569094',
      title: 'Spider-Man: Across the Spider-Verse',
      posterUrl: '/8Vt6mAwTZpY18iFovzYvL6xLAYw.jpg',
      backdropUrl: '/4XM826v92E3v1f855e9m.jpg',
      overview: 'After reuniting with Gwen Stacy, Brooklyn full-time, friendly neighborhood Spider-Man is catapulted across the Multiverse.',
      rating: 8.4,
      mediaType: 'movie',
    ),
  ];

  static final List<Movie> _seedActionMovies = [
    Movie(
      id: '603692',
      title: 'John Wick: Chapter 4',
      posterUrl: '/vZloFAK7NawQUvZvBwJHxM2T0Lp.jpg',
      backdropUrl: '/h8gWv1f855e9m.jpg',
      overview: 'With the price on his head ever increasing, John Wick takes his fight against the High Table global as he seeks out the most powerful players in the underworld.',
      rating: 7.8,
      mediaType: 'movie',
    ),
    Movie(
      id: '786892',
      title: 'Furiosa: A Mad Max Saga',
      posterUrl: '/iADOJ1f855e9m.jpg',
      backdropUrl: '/w1f855e9m.jpg',
      overview: 'As the world fell, young Furiosa is snatched from the Green Place of Many Mothers and falls into the hands of a great Biker Horde led by the Warlord Dementus.',
      rating: 7.6,
      mediaType: 'movie',
    ),
    Movie(
      id: '361743',
      title: 'Top Gun: Maverick',
      posterUrl: '/62v92E3v1f855e9m.jpg',
      backdropUrl: '/d1f855e9m.jpg',
      overview: 'After more than thirty years of service as one of the Navy top aviators, Pete Mitchell is where he belongs, pushing the envelope as a courageous test pilot.',
      rating: 8.2,
      mediaType: 'movie',
    ),
  ];

  static final List<Movie> _seedTrendingTv = [
    Movie(
      id: '66732',
      title: 'Stranger Things',
      posterUrl: '/49WJfeN0mG2BBJHxM2T0Lp.jpg',
      backdropUrl: '/56gWv1f855e9m.jpg',
      overview: 'When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces and one strange little girl.',
      rating: 8.6,
      mediaType: 'tv',
    ),
    Movie(
      id: '94997',
      title: 'House of the Dragon',
      posterUrl: '/1XS1f855e9m.jpg',
      backdropUrl: '/2Yv1f855e9m.jpg',
      overview: 'The Targaryen dynasty is at the absolute apex of its power, with more than 15 dragons under their command.',
      rating: 8.4,
      mediaType: 'tv',
    ),
    Movie(
      id: '100088',
      title: 'The Last of Us',
      posterUrl: '/uKv1f855e9m.jpg',
      backdropUrl: '/3Zv1f855e9m.jpg',
      overview: 'Twenty years after modern civilization has been destroyed, Joel, a hardened survivor, is hired to smuggle Ellie, a 14-year-old girl, out of an oppressive quarantine zone.',
      rating: 8.6,
      mediaType: 'tv',
    ),
  ];

  static final List<Movie> _seedAnimeCollection = [
    Movie(
      id: '1429',
      title: 'Attack on Titan',
      posterUrl: '/hTP1f855e9m.jpg',
      backdropUrl: '/6Qv1f855e9m.jpg',
      overview: 'After his hometown is destroyed and his mother is killed, young Eren Jaeger vows to cleanse the earth of the giant humanoid Titans that have brought humanity to the brink of extinction.',
      rating: 8.7,
      mediaType: 'tv',
    ),
    Movie(
      id: '85937',
      title: 'Demon Slayer: Kimetsu no Yaiba',
      posterUrl: '/x2v1f855e9m.jpg',
      backdropUrl: '/7Rv1f855e9m.jpg',
      overview: 'It is the Taisho Period in Japan. Tanjiro, a kindhearted boy who sells charcoal for a living, finds his family slaughtered by a demon.',
      rating: 8.6,
      mediaType: 'tv',
    ),
    Movie(
      id: '95479',
      title: 'Jujutsu Kaisen',
      posterUrl: '/eH1f855e9m.jpg',
      backdropUrl: '/8Qv1f855e9m.jpg',
      overview: 'A boy fights... for "the right death". Hardship, regret, shame: the negative feelings that humans feel become Curses that lurk in our everyday lives.',
      rating: 8.5,
      mediaType: 'tv',
    ),
  ];

  /// Initialize preloaded cache synchronously or async on startup
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      _cache[_keyTrendingMovies] = _loadCollectionFromPrefs(prefs, _keyTrendingMovies, _seedTrendingMovies);
      _cache[_keyActionMovies] = _loadCollectionFromPrefs(prefs, _keyActionMovies, _seedActionMovies);
      _cache[_keyTrendingTv] = _loadCollectionFromPrefs(prefs, _keyTrendingTv, _seedTrendingTv);
      _cache[_keyAnimeCollection] = _loadCollectionFromPrefs(prefs, _keyAnimeCollection, _seedAnimeCollection);

      _initialized = true;
    } catch (e) {
      debugPrint('[PreloadService] Error loading cache: $e');
      // Fallback to seed datasets
      _cache[_keyTrendingMovies] = _seedTrendingMovies;
      _cache[_keyActionMovies] = _seedActionMovies;
      _cache[_keyTrendingTv] = _seedTrendingTv;
      _cache[_keyAnimeCollection] = _seedAnimeCollection;
      _initialized = true;
    }
  }

  static List<Movie> _loadCollectionFromPrefs(SharedPreferences prefs, String key, List<Movie> fallback) {
    try {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(jsonStr);
        final list = decoded.map((item) => Movie.fromJson(item as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('[PreloadService] Failed parsing $key: $e');
    }
    return fallback;
  }

  static List<Movie> getTrendingMovies() {
    return _cache[_keyTrendingMovies] ?? _seedTrendingMovies;
  }

  static List<Movie> getActionMovies() {
    return _cache[_keyActionMovies] ?? _seedActionMovies;
  }

  static List<Movie> getTrendingTv() {
    return _cache[_keyTrendingTv] ?? _seedTrendingTv;
  }

  static List<Movie> getAnimeCollection() {
    return _cache[_keyAnimeCollection] ?? _seedAnimeCollection;
  }

  static List<Movie> getCollection(String key) {
    return _cache[key] ?? [];
  }

  /// Save collection into memory & persistent SharedPreferences
  static Future<void> saveCollection(String key, List<Movie> movies) async {
    if (movies.isEmpty) return;
    _cache[key] = movies;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(movies.map((m) => m.toJson()).toList());
      await prefs.setString(key, jsonStr);
    } catch (e) {
      debugPrint('[PreloadService] Error saving cache for $key: $e');
    }
  }

  static Future<void> saveTrendingMovies(List<Movie> movies) => saveCollection(_keyTrendingMovies, movies);
  static Future<void> saveActionMovies(List<Movie> movies) => saveCollection(_keyActionMovies, movies);
  static Future<void> saveTrendingTv(List<Movie> movies) => saveCollection(_keyTrendingTv, movies);
  static Future<void> saveAnimeCollection(List<Movie> movies) => saveCollection(_keyAnimeCollection, movies);

  /// Pre-cache poster images into disk & memory cache so images render instantly offline
  static void precacheMovieImages(BuildContext context, List<Movie> movies) {
    for (final movie in movies.take(15)) {
      if (movie.posterUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(movie.posterUrl), context).catchError((_) {});
      }
      if (movie.backdropUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(movie.backdropUrl), context).catchError((_) {});
      }
    }
  }
}
