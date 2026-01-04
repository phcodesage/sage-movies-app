import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sagemovies/models/movie.dart';

class ApiService {
  // Use your production API
  static const String baseUrl = 'https://sagemovies.site';
  
  // For local development, you can switch to:
  // static const String baseUrl = 'http://localhost:3000';

  // Fetch trending movies
  static Future<List<Movie>> fetchTrending({String type = 'movie'}) async {
    try {
      print('[API] Fetching trending $type from $baseUrl/api/trending/$type');
      final response = await http.get(
        Uri.parse('$baseUrl/api/trending/$type'),
      );

      print('[API] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        print('[API] Got ${results.length} trending $type items');
        final movies = results.map((json) => Movie.fromJson(json)).toList();
        if (movies.isNotEmpty) {
          print('[API] First movie: ${movies[0].title}, posterUrl: ${movies[0].posterUrl}');
        }
        return movies;
      } else {
        print('[API] Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load trending $type');
      }
    } catch (e) {
      print('[API] Error fetching trending: $e');
      return [];
    }
  }

  // Fetch movie collection
  static Future<List<Movie>> fetchMovieCollection() async {
    try {
      print('[API] Fetching movie collection');
      final response = await http.get(
        Uri.parse('$baseUrl/api/movies/collection'),
      );

      print('[API] Movie collection response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        print('[API] Got ${results.length} movies in collection');
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movie collection');
      }
    } catch (e) {
      print('[API] Error fetching movie collection: $e');
      return [];
    }
  }

  // Fetch TV collection (romance movies in your API)
  static Future<List<Movie>> fetchTvCollection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/tv/collection'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load TV collection');
      }
    } catch (e) {
      print('[API] Error fetching TV collection: $e');
      return [];
    }
  }

  // Fetch anime collection
  static Future<List<Movie>> fetchAnimeCollection() async {
    try {
      print('[API] Fetching anime collection');
      final response = await http.get(
        Uri.parse('$baseUrl/api/anime/collection'),
      );

      print('[API] Anime collection response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        print('[API] Got ${results.length} anime items');
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load anime collection');
      }
    } catch (e) {
      print('[API] Error fetching anime collection: $e');
      return [];
    }
  }

  // Fetch movies by genre
  static Future<List<Movie>> fetchMoviesByGenre(int genreId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/movies/genre/$genreId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies by genre');
      }
    } catch (e) {
      print('[API] Error fetching movies by genre: $e');
      return [];
    }
  }

  // Search movies and TV shows
  static Future<List<Movie>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/search?query=${Uri.encodeComponent(query)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search');
      }
    } catch (e) {
      print('[API] Error searching: $e');
      return [];
    }
  }

  // Fetch movie/TV details
  static Future<Movie?> fetchDetails(String type, int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/details/$type/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Movie.fromJson(data);
      } else {
        throw Exception('Failed to load details');
      }
    } catch (e) {
      print('[API] Error fetching details: $e');
      return null;
    }
  }

  // Get video embed URL
  static Future<String?> getVideoSource(String type, String id, {String server = 'vidsrc.cc'}) async {
    try {
      final url = '$baseUrl/api/video-sources/$type/$id?server=$server';
      print('[API] Requesting video source: $url');
      
      final response = await http.get(Uri.parse(url));
      print('[API] Video source response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final embedURL = data['embedURL'] as String?;
        print('[API] Got embedURL: $embedURL');
        
        if (embedURL == null || embedURL.isEmpty) {
          print('[API] WARNING: embedURL is null or empty for id=$id');
        }
        
        return embedURL;
      } else {
        print('[API] Error response: ${response.body}');
        throw Exception('Failed to get video source: ${response.statusCode}');
      }
    } catch (e) {
      print('[API] Error getting video source for id=$id, type=$type, server=$server: $e');
      return null;
    }
  }

  // Helper to build image URL
  static String getImageUrl(String? path, {bool isBackdrop = false}) {
    if (path == null || path.isEmpty) return '';
    
    // TMDB image base URL
    final size = isBackdrop ? 'w1280' : 'w500';
    return 'https://image.tmdb.org/t/p/$size$path';
  }
}
