import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sagemovies/models/movie.dart';

class ApiService {
  // Production API URL
  static const String baseUrl = 'https://sagemovies.netlify.app';

  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36',
  };

  // Fetch trending movies
  static Future<List<Movie>> fetchTrending({String type = 'movie'}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/trending/$type'),
        headers: defaultHeaders,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load trending $type');
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch movie collection
  static Future<List<Movie>> fetchMovieCollection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/movies/collection'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movie collection');
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch TV collection
  static Future<List<Movie>> fetchTvCollection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tv/collection'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load TV collection');
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch anime collection
  static Future<List<Movie>> fetchAnimeCollection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/anime/collection'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load anime collection');
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch movies by genre
  static Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/movies/genre/$genreId'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies by genre');
      }
    } catch (e) {
      return [];
    }
  }

  // Search movies and TV shows
  static Future<List<Movie>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/search?query=${Uri.encodeComponent(query)}'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search');
      }
    } catch (e) {
      return [];
    }
  }

  // Fetch movie/TV details
  static Future<Movie?> fetchDetails(String type, int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/details/$type/$id'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data);
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      return null;
    }
  }

  // Get video embed URL
  static Future<String?> getVideoSource(String type, String id, {String server = 'player.videasy.net'}) async {
    try {
      final url = '$baseUrl/api/video-sources/$type/$id?server=$server';
      final response = await http.get(
        Uri.parse(url),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['embedURL'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Fetch full details including production companies (studios)
  static Future<Map<String, dynamic>?> fetchFullDetails(String type, String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/movie/$id?type=$type'),
        headers: defaultHeaders,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // fallback
    }
    return null;
  }

  // Fetch movies by studio (production company)
  static Future<List<Movie>> fetchMoviesByStudio(int studioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/movies/studio/$studioId'),
        headers: defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      }
    } catch (e) {
      // fallback
    }
    return [];
  }

  // Helper to build image URL
  static String getImageUrl(String? path, {bool isBackdrop = false}) {
    if (path == null || path.isEmpty) return '';
    final size = isBackdrop ? 'w1280' : 'w500';
    return 'https://image.tmdb.org/t/p/$size$path';
  }

  // Pre-check server availability
  static Future<Map<String, dynamic>?> checkServers(String type, String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/check-servers?type=$type&id=$id'),
            headers: defaultHeaders,
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
