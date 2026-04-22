import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veto/core/domain/entities/room.dart';
import 'package:veto/core/domain/entities/vote.dart';
import 'package:veto/core/providers/repositories.dart';

final roomStreamProvider = StreamProvider.family<Room?, String>((
  ref,
  roomCode,
) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  return roomRepository.watchRoom(roomCode);
});

final voteStreamProvider = StreamProvider.autoDispose
    .family<Vote?, ({String roomCode, String movieId})>((ref, params) {
      final votingRepository = ref.watch(votingRepositoryProvider);
      return votingRepository.watchVote(params.roomCode, params.movieId);
    });

// Provider for current room code (could be stored using StateProvider)
final currentRoomCodeProvider = StateProvider<String?>((ref) => null);

// Provider for current player device ID
final playerDeviceIdProvider = StateProvider<String?>((ref) => null);
