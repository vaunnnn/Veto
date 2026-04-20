import 'package:veto/core/domain/repositories/room_repository.dart';
import 'package:veto/core/domain/repositories/voting_repository.dart';

class VotingService {
  final RoomRepository _roomRepository;
  final VotingRepository _votingRepository;

  VotingService({
    required RoomRepository roomRepository,
    required VotingRepository votingRepository,
  }) : _roomRepository = roomRepository,
       _votingRepository = votingRepository;

  Future<void> castVote({
    required String roomCode,
    required String movieId,
    required String playerDeviceId,
    required bool isLike,
  }) async {
    if (!isLike) {
      // Veto logic
      await _votingRepository.castVote(
        roomCode,
        movieId,
        playerDeviceId,
        false,
      );
      return;
    }

    // Like logic with consensus check
    await _votingRepository.castVote(roomCode, movieId, playerDeviceId, true);

    // Note: The consensus checking logic (checking if all players liked)
    // should be handled in the repository implementation or via Firestore triggers
    // For now, we'll keep the transaction logic in the Firebase repository
  }

  Future<void> clearMatch(String roomCode) async {
    await _roomRepository.clearMatch(roomCode);
  }
}
