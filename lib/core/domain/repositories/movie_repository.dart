import 'package:veto/core/domain/entities/movie.dart';
import 'package:veto/core/domain/entities/movie_details.dart';

abstract class MovieRepository {
  Future<List<Movie>> discoverMovies({
    required List<String> genres,
    required int minYear,
    required int maxYear,
    required double minScore,
    required String maxRuntime,
    required bool familyFriendly,
    required List<String> languages,
    required int page,
  });

  Future<MovieDetails?> getMovieDetails(int movieId);
  Future<List<Movie>> searchMovies(String query);
}
