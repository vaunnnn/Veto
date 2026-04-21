import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/core/domain/entities/movie.dart';

class Match {
  final Movie movie;
  final DateTime matchedAt;
  final List<String> matchedBy; // player device IDs who liked it

  Match({
    required this.movie,
    required this.matchedAt,
    required this.matchedBy,
  });

  factory Match.fromFirestore(Map<String, dynamic> data) {
    return Match(
      movie: Movie.fromJson(data['movie'] as Map<String, dynamic>),
      matchedAt: (data['matchedAt'] as Timestamp).toDate(),
      matchedBy: List<String>.from(data['matchedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'movie': movie.toJson(),
      'matchedAt': Timestamp.fromDate(matchedAt),
      'matchedBy': matchedBy,
    };
  }
}
