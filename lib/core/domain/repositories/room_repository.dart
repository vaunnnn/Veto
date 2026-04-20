import 'package:veto/core/domain/entities/room.dart';

abstract class RoomRepository {
  Future<String> createRoom(String hostDeviceId);
  Future<bool> joinRoom(String roomCode, String playerDeviceId);
  Stream<Room?> watchRoom(String roomCode);
  Future<void> updateRoomStatus(String roomCode, String status);
  Future<void> updatePlayerProfile(
    String roomCode,
    String playerDeviceId,
    Map<String, dynamic> profile,
  );
  Future<void> updateFilterSettings(
    String roomCode,
    Map<String, dynamic> settings,
  );
  Future<void> leaveRoom(String roomCode, String playerDeviceId);
  Future<void> deleteRoom(String roomCode);
  Future<void> clearMatch(String roomCode);
}
