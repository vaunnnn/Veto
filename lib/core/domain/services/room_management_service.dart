import 'package:veto/core/domain/repositories/room_repository.dart';

class RoomManagementService {
  final RoomRepository _roomRepository;

  RoomManagementService({required RoomRepository roomRepository})
    : _roomRepository = roomRepository;

  Future<String> createRoom(String hostDeviceId) async {
    return await _roomRepository.createRoom(hostDeviceId);
  }

  Future<bool> joinRoom(String roomCode, String playerDeviceId) async {
    return await _roomRepository.joinRoom(roomCode, playerDeviceId);
  }

  Future<void> leaveRoom(String roomCode, String playerDeviceId) async {
    await _roomRepository.leaveRoom(roomCode, playerDeviceId);
  }

  Future<void> deleteRoom(String roomCode) async {
    await _roomRepository.deleteRoom(roomCode);
  }

  Future<void> updatePlayerProfile(
    String roomCode,
    String playerDeviceId,
    String name,
    String? avatar,
    bool isHost,
  ) async {
    await _roomRepository.updatePlayerProfile(roomCode, playerDeviceId, {
      'deviceId': playerDeviceId,
      'name': name,
      'avatar': avatar,
      'isHost': isHost,
    });
  }

  Future<void> updatePlayerGenres(
    String roomCode,
    String playerDeviceId,
    List<String> genres,
  ) async {
    await _roomRepository.updatePlayerProfile(roomCode, playerDeviceId, {
      'deviceId': playerDeviceId,
      'genres': genres,
    });
  }

  Future<void> updateFilterSettings(
    String roomCode,
    Map<String, dynamic> settings,
  ) async {
    await _roomRepository.updateFilterSettings(roomCode, settings);
  }

  Future<void> updateRoomStatus(String roomCode, String status) async {
    await _roomRepository.updateRoomStatus(roomCode, status);
  }

  Future<void> kickPlayer(String roomCode, String playerDeviceId) async {
    await _roomRepository.leaveRoom(roomCode, playerDeviceId);
  }
}
