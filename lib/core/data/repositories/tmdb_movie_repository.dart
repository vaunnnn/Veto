import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:veto/core/domain/entities/movie.dart';
import 'package:veto/core/domain/entities/movie_details.dart';
import 'package:veto/core/domain/repositories/movie_repository.dart';

class TmdbMovieRepository implements MovieRepository {
  final String _apiKey;
  final http.Client _client;

  TmdbMovieRepository({String? apiKey, http.Client? client})
    : _apiKey = apiKey ?? dotenv.env['TMDB_API_KEY'] ?? '',
      _client = client ?? http.Client();

  @override
  Future<List<Movie>> discoverMovies({
    required List<String> genres,
    required int minYear,
    required int maxYear,
    required double minScore,
    required String maxRuntime,
    required bool familyFriendly,
    required List<String> languages,
    required int page,
  }) async {
    // Convert genre names to IDs if needed
    final genreIds = genres.where((id) => id.isNotEmpty).join('|');

    // Build URL
    String urlStr =
        'https://api.themoviedb.org/3/discover/movie?api_key=$_apiKey&with_genres=$genreIds&sort_by=popularity.desc&page=$page';

    urlStr += '&vote_count.gte=150&vote_average.gte=$minScore';
    urlStr +=
        '&primary_release_date.gte=$minYear-01-01&primary_release_date.lte=$maxYear-12-31';

    if (maxRuntime != 'Any Length') {
      int minutes = maxRuntime == 'Under 90 Mins'
          ? 90
          : maxRuntime == 'Under 2 Hours'
          ? 120
          : 150;
      urlStr += '&with_runtime.lte=$minutes';
    }

    if (familyFriendly) {
      urlStr += '&certification_country=US&certification.lte=PG-13';
    }

    // Language mapping
    final Map<String, String> tmdbLanguageCodes = {
      'Arabic': 'ar',
      'Chinese': 'zh',
      'English': 'en',
      'French': 'fr',
      'German': 'de',
      'Hindi': 'hi',
      'Italian': 'it',
      'Japanese': 'ja',
      'Korean': 'ko',
      'Portuguese': 'pt',
      'Russian': 'ru',
      'Spanish': 'es',
    };

    if (languages.isNotEmpty) {
      List<String> codes = languages
          .where((lang) => tmdbLanguageCodes.containsKey(lang))
          .map((lang) => tmdbLanguageCodes[lang]!)
          .toList();

      if (codes.isNotEmpty) {
        urlStr += '&with_original_language=${codes.join('|')}';
      }
    }

    try {
      final url = Uri.parse(urlStr);
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = List<Map<String, dynamic>>.from(data['results']);
        return results.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  @override
  Future<MovieDetails?> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      'https://api.themoviedb.org/3/movie/$movieId?api_key=$_apiKey&append_to_response=credits,reviews',
    );

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final crew = data['credits']?['crew'] as List? ?? [];
        final directorObj = crew.firstWhere(
          (member) => member['job'] == 'Director',
          orElse: () => null,
        );
        final directorName = directorObj != null
            ? directorObj['name']
            : 'Unknown';

        final castList = data['credits']?['cast'] as List? ?? [];
        final topCast = castList
            .take(4)
            .map((c) => c['name'].toString())
            .toList();

        final reviewList = data['reviews']?['results'] as List? ?? [];
        final topReviews = reviewList
            .take(2)
            .map(
              (r) => {
                'author': r['author'].toString(),
                'content': r['content'].toString(),
              },
            )
            .toList();

        return MovieDetails(
          director: directorName,
          cast: topCast,
          reviews: topReviews,
        );
      }
    } catch (e) {
      print("Error fetching movie details: $e");
    }

    return null;
  }

  @override
  Future<List<Movie>> searchMovies(String query) {
    // TODO: Implement search functionality
    throw UnimplementedError();
  }
}
