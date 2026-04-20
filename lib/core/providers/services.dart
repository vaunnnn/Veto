import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veto/core/domain/services/room_management_service.dart';
import 'package:veto/core/domain/services/voting_service.dart';
import 'package:veto/core/domain/services/movie_filter_service.dart';
import 'package:veto/core/services/device_id_service.dart';
import 'package:veto/core/providers/repositories.dart';

final roomManagementServiceProvider = Provider<RoomManagementService>((ref) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  return RoomManagementService(roomRepository: roomRepository);
});

final votingServiceProvider = Provider<VotingService>((ref) {
  final roomRepository = ref.watch(roomRepositoryProvider);
  final votingRepository = ref.watch(votingRepositoryProvider);
  return VotingService(
    roomRepository: roomRepository,
    votingRepository: votingRepository,
  );
});

final movieFilterServiceProvider = Provider<MovieFilterService>((ref) {
  final movieRepository = ref.watch(movieRepositoryProvider);
  return MovieFilterService(movieRepository: movieRepository);
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService();
});
