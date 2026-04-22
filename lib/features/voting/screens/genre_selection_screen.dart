import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:veto/core/themes/app_colors.dart';
import 'package:veto/core/providers/providers.dart';
import 'package:veto/core/domain/entities/room.dart';
import 'package:veto/features/rooms/screens/landing_screen.dart';
import 'swipe_deck_screen.dart';

class GenreSelectionScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final String playerDeviceId;

  const GenreSelectionScreen({
    super.key,
    required this.roomCode,
    required this.playerDeviceId,
  });

  @override
  ConsumerState<GenreSelectionScreen> createState() =>
      _GenreSelectionScreenState();
}

class _GenreSelectionScreenState extends ConsumerState<GenreSelectionScreen> {
  bool _isHost = false;
  bool _navigatedAway = false;
  bool _isWaitingDialogShowing = false; // Track if dialog is open
  Room? _currentRoom;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleRoomUpdate(
    AsyncValue<Room?>? previous,
    AsyncValue<Room?> next,
  ) async {
    next.when(
      data: (room) async {
        if (room == null) {
          // Room deleted, navigate to landing screen
          if (!_navigatedAway && mounted) {
            _navigatedAway = true;
            if (_isWaitingDialogShowing) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pop(); // Safely clear dialog
            }
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
            );
          }
          return;
        }

        final bool isHost = room.hostId == widget.playerDeviceId;
        if (_isHost != isHost && mounted) {
          setState(() {
            _isHost = isHost;
            _currentRoom = room;
          });
        } else if (mounted) {
          setState(() {
            _currentRoom = room;
          });
        }

        // Prevent execution if we have already transitioned
        if (_navigatedAway) return;

        // 1. UPDATE STATUS LOGIC: Only the host should push the "swiping" status to prevent race conditions.
        if (isHost &&
            room.status != RoomStatus.swiping &&
            room.connectedPlayers.isNotEmpty) {
          bool allReady = true;
          for (String id in room.connectedPlayers) {
            final profile = room.playerProfiles[id];
            if (profile == null || (profile.genres ?? []).isEmpty) {
              allReady = false;
              break;
            }
          }

          if (allReady) {
            try {
              await ref
                  .read(roomManagementServiceProvider)
                  .updateRoomStatus(widget.roomCode, 'swiping');
            } catch (e) {
              debugPrint('Failed to update room status to swiping: $e');
            }
          }
        }

        // 2. TELEPORTATION LOGIC: If the room is now 'swiping', teleport everyone cleanly.
        if (room.status == RoomStatus.swiping && mounted) {
          _navigatedAway = true;

          if (_isWaitingDialogShowing) {
            Navigator.of(
              context,
              rootNavigator: true,
            ).pop(); // Pop the dialog using the root navigator
          }

          // Push the new screen using the main State context
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SwipeDeckScreen(
                selectedGenres: selectedGenres,
                roomCode: widget.roomCode,
                playerDeviceId: widget.playerDeviceId,
              ),
            ),
          );
        }
      },
      error: (error, stackTrace) {
        debugPrint('Room Stream Error: $error');
      },
      loading: () {},
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _leaveRoom() async {
    final roomManagementService = ref.read(roomManagementServiceProvider);

    if (_isHost) {
      await roomManagementService.deleteRoom(widget.roomCode);
    } else {
      await roomManagementService.leaveRoom(
        widget.roomCode,
        widget.playerDeviceId,
      );
    }

    if (mounted) {
      _navigatedAway = true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  final List<Map<String, String>> genres = [
    {'name': 'Action', 'image': 'assets/images/action.webp'},
    {'name': 'Adventure', 'image': 'assets/images/adventure.webp'},
    {'name': 'Animation', 'image': 'assets/images/animation.webp'},
    {'name': 'Biography', 'image': 'assets/images/biography.webp'},
    {'name': 'Comedy', 'image': 'assets/images/comedy.webp'},
    {'name': 'Documentary', 'image': 'assets/images/documentary.webp'},
    {'name': 'Drama', 'image': 'assets/images/drama.webp'},
    {'name': 'Family', 'image': 'assets/images/family.webp'},
    {'name': 'Fantasy', 'image': 'assets/images/fantasy.webp'},
    {'name': 'History', 'image': 'assets/images/history.webp'},
    {'name': 'Horror', 'image': 'assets/images/horror.webp'},
    {'name': 'Musical', 'image': 'assets/images/musical.webp'},
    {'name': 'Mystery', 'image': 'assets/images/mystery.webp'},
    {'name': 'Romance', 'image': 'assets/images/romance.webp'},
    {'name': 'Sci-Fi', 'image': 'assets/images/sci-fi.webp'},
    {'name': 'Sport', 'image': 'assets/images/sport.webp'},
    {'name': 'Thriller', 'image': 'assets/images/thriller.webp'},
    {'name': 'Western', 'image': 'assets/images/western.webp'},
  ];

  final Set<String> selectedGenres = {};

  void _toggleGenre(String genre) {
    setState(() {
      if (selectedGenres.contains(genre)) {
        selectedGenres.remove(genre);
      } else {
        if (selectedGenres.length < 3) {
          selectedGenres.add(genre);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can only select up to 3 genres!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _showWaitingDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _isWaitingDialogShowing = true; // Mark dialog as open

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          // The Consumer now is PURELY for UI. Side effects were moved to `_handleRoomUpdate`.
          child: Consumer(
            builder: (context, ref, child) {
              final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));
              final room = roomAsync.value;

              if (room == null) {
                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final connectedPlayers = room.connectedPlayers;
              final profiles = room.playerProfiles;

              int readyCount = 0;
              List<Widget> playerStatusWidgets = [];

              for (String deviceId in connectedPlayers) {
                final List<dynamic> rawGenres;
                final profile = profiles[deviceId];
                final String name = profile?.name ?? 'Guest';
                final String avatar =
                    profile?.avatar ?? 'assets/images/default-pic-1.webp';

                if (deviceId == widget.playerDeviceId) {
                  rawGenres = selectedGenres.toList();
                } else {
                  rawGenres = profile?.genres ?? [];
                }

                final bool isReady = rawGenres.isNotEmpty;

                if (isReady) readyCount++;

                String subtitleText = 'Selecting...';
                if (isReady) {
                  subtitleText = rawGenres.map((g) => g.toString()).join(', ');
                }

                playerStatusWidgets.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade800,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('Failed to load image');
                          },
                          backgroundImage: avatar.startsWith('http')
                              ? NetworkImage(avatar) as ImageProvider
                              : AssetImage(avatar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isReady
                                      ? (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600)
                                      : Colors.red.shade400,
                                  fontSize: 11.5,
                                  fontWeight: isReady
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        isReady
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10B981),
                                size: 24,
                              )
                            : Icon(
                                Icons.more_horiz,
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey,
                                size: 24,
                              ),
                      ],
                    ),
                  ),
                );
              }
              
              int waitingFor = connectedPlayers.length - readyCount;
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Waiting for $waitingFor more...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sit tight, your group is making their picks.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...playerStatusWidgets,
                    const SizedBox(height: 16),
                    // TEMPORARY DEBUG UI
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'DEBUG SERVER DATA:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...connectedPlayers.map((id) {
                            final g = profiles[id]?.genres;
                            return Text(
                              '$id genres: ${g == null ? "null" : g.toString()}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                              ),
                            );
                          }),
                          if (roomAsync.hasError) ...[
                            const SizedBox(height: 8),
                            Text(
                              'STREAM ERROR: ${roomAsync.error}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(roomManagementServiceProvider)
                              .updatePlayerGenres(
                                widget.roomCode,
                                widget.playerDeviceId,
                                [],
                              );
                          if (dialogContext.mounted) {
                            Navigator.pop(
                              dialogContext,
                            ); // Use proper context here
                          }
                        },
                        child: Text(
                          'Cancel Selection',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((_) {
      // Revert track state if dismissed manually
      _isWaitingDialogShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    // Keep the provider alive even during dialog overlays
    ref.watch(roomStreamProvider(widget.roomCode));

    // This listener safely drives database and navigation actions outside the build scope.
    ref.listen<AsyncValue<Room?>>(
      roomStreamProvider(widget.roomCode),
      _handleRoomUpdate,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (_isHost) {
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('End Session?'),
              content: const Text(
                'This will delete the room for all players. Are you sure?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete Room & Leave'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _leaveRoom();
          }
        } else {
          final bool? confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Leave Room?'),
              content: const Text('This will remove you from the room.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Leave Room'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _leaveRoom();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isLightMode ? Colors.black : Colors.white,
                          fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                        ),
                        children: const [
                          TextSpan(text: "What's the "),
                          TextSpan(
                            text: "Vibe?",
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Select up to 3 genres you're in the mood for.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isLightMode ? Colors.black54 : Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  itemCount: genres.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final genre = genres[index];
                    final isSelected = selectedGenres.contains(genre['name']);
                    return _buildGenreCard(genre, isSelected);
                  },
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: selectedGenres.isEmpty
                          ? null
                          : () async {
                              final room =
                                  ref
                                      .read(roomStreamProvider(widget.roomCode))
                                      .value ??
                                  _currentRoom;
                              final connectedPlayers =
                                  room?.connectedPlayers ?? [];

                              await ref
                                  .read(roomManagementServiceProvider)
                                  .updatePlayerGenres(
                                    widget.roomCode,
                                    widget.playerDeviceId,
                                    selectedGenres.toList(),
                                  );

                              if (connectedPlayers.length <= 1) {
                                await ref
                                    .read(roomManagementServiceProvider)
                                    .updateRoomStatus(
                                      widget.roomCode,
                                      'swiping',
                                    );

                                if (context.mounted) {
                                  _navigatedAway =
                                      true; // Block listener duplication
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SwipeDeckScreen(
                                        selectedGenres: selectedGenres,
                                        roomCode: widget.roomCode,
                                        playerDeviceId: widget.playerDeviceId,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                _showWaitingDialog();
                              }
                            },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'START VETOING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.play_arrow_rounded, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreCard(Map<String, String> genre, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleGenre(genre['name']!),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 200,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.transparent, Colors.black],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    genre['image']!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        genre['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 14,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
