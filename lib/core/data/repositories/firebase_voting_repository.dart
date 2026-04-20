import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veto/core/domain/entities/vote.dart';
import 'package:veto/core/domain/repositories/voting_repository.dart';

class FirebaseVotingRepository implements VotingRepository {
  final FirebaseFirestore _firestore;

  FirebaseVotingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> castVote(
    String roomCode,
    String movieId,
    String playerDeviceId,
    bool isLike,
  ) async {
    final roomRef = _firestore.collection('rooms').doc(roomCode);
    final movieVoteRef = roomRef.collection('votes').doc(movieId);

    if (!isLike) {
      // Veto: just add to vetoes array
      await movieVoteRef.set({
        'vetoes': FieldValue.arrayUnion([playerDeviceId]),
      }, SetOptions(merge: true));
      return;
    }

    // Like: run transaction for consensus checking
    await _firestore.runTransaction((transaction) async {
      // 1. Check the main room to see how many players are connected
      final roomSnapshot = await transaction.get(roomRef);
      if (!roomSnapshot.exists) return;
      final int totalPlayers =
          (roomSnapshot.data()!['connectedPlayers'] as List?)?.length ?? 0;

      // 2. Check the movie's specific vote document
      final movieSnapshot = await transaction.get(movieVoteRef);
      List likes = [];
      List vetoes = [];

      if (movieSnapshot.exists) {
        likes = List.from(movieSnapshot.data()!['likes'] ?? []);
        vetoes = List.from(movieSnapshot.data()!['vetoes'] ?? []);
      }

      // If someone already vetoed it, abort!
      if (vetoes.isNotEmpty) return;

      // 3. Add our like
      if (!likes.contains(playerDeviceId)) {
        likes.add(playerDeviceId);
      }

      // Save the like to the movie's private document
      transaction.set(movieVoteRef, {'likes': likes}, SetOptions(merge: true));

      // Consensus check: if all players liked, create a match
      if (likes.length == totalPlayers && totalPlayers > 0) {
        // Get movie details from votes collection or need to pass movie data
        // For now, we'll update with a placeholder - the actual movie data
        // should be passed from the caller or fetched separately
        transaction.update(roomRef, {
          'latestMatch': {'id': movieId}, // Placeholder
          'matchedMovies': FieldValue.arrayUnion([
            {'id': movieId},
          ]),
        });
      }
    });
  }

  @override
  Stream<Vote?> watchVote(String roomCode, String movieId) {
    return _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('votes')
        .doc(movieId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return Vote.fromFirestore(snapshot);
          }
          return null;
        });
  }

  @override
  Future<void> clearVeto(String roomCode, String movieId) async {
    final movieVoteRef = _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('votes')
        .doc(movieId);

    await movieVoteRef.update({'vetoes': FieldValue.delete()});
  }

  @override
  Future<Map<String, Vote>> getVotesForRoom(String roomCode) async {
    final snapshot = await _firestore
        .collection('rooms')
        .doc(roomCode)
        .collection('votes')
        .get();

    final votes = <String, Vote>{};
    for (var doc in snapshot.docs) {
      votes[doc.id] = Vote.fromFirestore(doc);
    }

    return votes;
  }
}
