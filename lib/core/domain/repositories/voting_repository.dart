import 'package:veto/core/domain/entities/vote.dart';

abstract class VotingRepository {
  Future<void> castVote(
    String roomCode,
    String movieId,
    String playerDeviceId,
    bool isLike,
  );
  Stream<Vote?> watchVote(String roomCode, String movieId);
  Future<void> clearVeto(String roomCode, String movieId);
  Future<Map<String, Vote>> getVotesForRoom(String roomCode);
}
