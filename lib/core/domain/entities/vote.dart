import 'package:cloud_firestore/cloud_firestore.dart';

class Vote {
  final String movieId;
  final List<String> likes;
  final List<String> vetoes;

  Vote({required this.movieId, required this.likes, required this.vetoes});

  factory Vote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vote(
      movieId: doc.id,
      likes: List<String>.from(data['likes'] ?? []),
      vetoes: List<String>.from(data['vetoes'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {'likes': likes, 'vetoes': vetoes};
  }

  Vote copyWith({String? movieId, List<String>? likes, List<String>? vetoes}) {
    return Vote(
      movieId: movieId ?? this.movieId,
      likes: likes ?? this.likes,
      vetoes: vetoes ?? this.vetoes,
    );
  }

  bool get hasVeto => vetoes.isNotEmpty;
  bool get isUnanimousLike => likes.isNotEmpty && vetoes.isEmpty;
  int get likeCount => likes.length;
}
