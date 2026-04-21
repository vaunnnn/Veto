import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veto/core/data/repositories/firebase_room_repository.dart';
import 'package:veto/core/data/repositories/firebase_voting_repository.dart';
import 'package:veto/core/data/repositories/tmdb_movie_repository.dart';
import 'package:veto/core/domain/repositories/room_repository.dart';
import 'package:veto/core/domain/repositories/movie_repository.dart';
import 'package:veto/core/domain/repositories/voting_repository.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return FirebaseRoomRepository();
});

final movieRepositoryProvider = Provider<MovieRepository>((ref) {
  return TmdbMovieRepository();
});

final votingRepositoryProvider = Provider<VotingRepository>((ref) {
  return FirebaseVotingRepository();
});
