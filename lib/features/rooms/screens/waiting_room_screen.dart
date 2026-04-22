import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:veto/features/voting/screens/genre_selection_screen.dart';
import 'package:veto/features/rooms/widgets/qr_code_widget.dart';
import 'package:veto/features/rooms/widgets/player_card_widget.dart';
import 'package:veto/core/providers/providers.dart';
import 'package:veto/core/domain/entities/room.dart';
import 'landing_screen.dart';

class WaitingRoomScreen extends ConsumerStatefulWidget {
  final String roomCode;
  final bool isHost;
  final String playerDeviceId;

  const WaitingRoomScreen({
    super.key,
    required this.roomCode,
    required this.playerDeviceId,
    this.isHost = false,
  });

  @override
  ConsumerState<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends ConsumerState<WaitingRoomScreen> {
  // This is our background listener that watches for kicks and teleports
  bool _isHost = false;
  bool _navigatedAway = false;

  @override
  void initState() {
    super.initState();
    _isHost = widget.isHost;
  }

  // --- THE MAGIC TELEPORT & KICK LOGIC ---
  void _handleRoomUpdate(AsyncValue<Room?>? previous, AsyncValue<Room?> next) {
    next.when(
      data: (room) {
        if (room == null) {
          // Room deleted, navigate to landing screen (only show snackbar for guests)
          if (!_navigatedAway && mounted && !_isHost) {
            _navigatedAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('The host has closed the session.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Update host status based on stored hostId
        final bool isHost = room.hostId == widget.playerDeviceId;
        if (_isHost != isHost && mounted) {
          setState(() {
            _isHost = isHost;
          });
        }

        // Check if this specific user was kicked!
        if (!_isHost &&
            !room.connectedPlayers.contains(widget.playerDeviceId)) {
          if (!_navigatedAway && mounted) {
            _navigatedAway = true;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have been removed from the session.'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LandingScreen()),
              (route) => false,
            );
          }
          return;
        }

        // Teleport everyone if the host starts the session
        if (room.status == RoomStatus.voting) {
          if (!_navigatedAway && mounted) {
            _navigatedAway = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => GenreSelectionScreen(
                  roomCode: widget.roomCode,
                  playerDeviceId: widget.playerDeviceId,
                ),
              ),
            );
          }
        }
      },
      error: (error, stackTrace) {
        // Handle error if needed
      },
      loading: () {
        // Loading state if needed
      },
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

  Future<bool> _onWillPop() async {
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
      return false;
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
      return false;
    }
  }

  // 1. A fun list of pre-made avatars
  final List<String> availableAvatars = [
    'assets/images/default-pic-1.webp',
    'assets/images/default-pic-2.webp',
    'assets/images/default-pic-3.webp',
    'assets/images/default-pic-4.webp',
    'assets/images/default-pic-5.webp',
    'assets/images/default-pic-6.webp',
  ];

  // 2. The Pop-up Dialog
  // 2. The Pop-up Dialog
  void _showEditProfileDialog(String currentName, String currentAvatar) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    String newAvatar = currentAvatar;

    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final avatarBgColor = isDarkMode ? Colors.white : Colors.grey.shade300;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                      controller: nameController,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: availableAvatars.map((url) {
                        bool isSelected = newAvatar == url;
                        return GestureDetector(
                          onTap: () => setDialogState(() => newAvatar = url),
                          child: Container(
                            // NEW: Adds a 3-pixel gap between the avatar and the selection ring!
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context)
                                          .colorScheme
                                          .primary // The red selection color
                                    : Colors.transparent,
                                width: 2.0, // A thin, clean outline
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              // NEW: Applies your grey/white background behind the transparent PNGs
                              backgroundColor: avatarBgColor,
                              backgroundImage: AssetImage(url),
                              radius: 36,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // Makes the Cancel splash a very soft, clean version of your primary color
                    overlayColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    overlayColor: Colors.white.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    final String finalName = nameController.text.trim();

                    final roomManagementService = ref.read(
                      roomManagementServiceProvider,
                    );
                    await roomManagementService.updatePlayerProfile(
                      widget.roomCode,
                      widget.playerDeviceId,
                      finalName.isEmpty ? 'Guest' : finalName,
                      newAvatar,
                      _isHost,
                    );

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQRCodeDialog(String roomCode) {
    try {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final qrColor = isDarkMode ? Colors.white : Colors.black;
      final bgColor = isDarkMode ? Colors.black : Colors.white;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Room QR Code',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrCodeWidget(
                  data: roomCode,
                  size: 200.0,
                  color: qrColor,
                  backgroundColor: bgColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code to join the room',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                roomCode,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CLOSE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      log('QR code generation failed', error: e, stackTrace: stackTrace);
      _showQRCodeFallback(roomCode);
    }
  }

  void _showQRCodeFallback(String roomCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Room Code',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'QR code generation unavailable',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'ROOM CODE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: roomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room code copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          roomCode,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this code with friends to join',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CLOSE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. THE HOST SETTINGS MODAL ---
  void _showHostSettingsModal() async {
    final roomAsync = ref.read(roomStreamProvider(widget.roomCode));
    final currentSettings = roomAsync.value?.filterSettings.toMap() ?? {};

    double minYear = (currentSettings['minYear'] ?? 1970).toDouble();
    double maxYear = (currentSettings['maxYear'] ?? DateTime.now().year)
        .toDouble();
    double minScore = (currentSettings['minScore'] ?? 6.0).toDouble();
    String maxRuntime = currentSettings['maxRuntime'] ?? 'Any Length';
    bool familyFriendly = currentSettings['familyFriendly'] ?? false;
    List<dynamic> rawLangs = currentSettings['languages'] ?? [];
    List<String> selectedLanguages = rawLangs.map((e) => e.toString()).toList();

    final List<String> availableLanguages = [
      'Arabic',
      'Chinese',
      'English',
      'French',
      'German',
      'Hindi',
      'Italian',
      'Japanese',
      'Korean',
      'Portuguese',
      'Russian',
      'Spanish',
    ];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;
            final subtleColor = isDark
                ? Colors.grey.shade500
                : Colors.grey.shade400;

            String scoreBadgeText = "ANYTHING GOES";
            if (minScore >= 8.0) {
              scoreBadgeText = "CRITICALLY ACCLAIMED";
            } else if (minScore >= 7.0) {
              scoreBadgeText = "CERTIFIED GOOD";
            } else if (minScore >= 5.0) {
              scoreBadgeText = "HIT OR MISS";
            }

            return Container(
              // THE FIX: Removed the hard-coded height so the modal perfectly hugs its contents
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                // THE FIX: Tells the column to only take up as much space as it needs
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Host Settings",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Refine the room's film pool",
                            style: TextStyle(fontSize: 14, color: subtleColor),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Divider(color: subtleColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 24),

                  // --- SLIDER 1: RELEASE YEAR ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RELEASE YEAR",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: subtleColor,
                        ),
                      ),
                      Text(
                        "${minYear.toInt()} — ${maxYear.toInt()}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: subtleColor.withValues(alpha: 0.2),
                      thumbColor: Colors.white,
                      trackHeight: 6.0,
                    ),
                    child: RangeSlider(
                      values: RangeValues(minYear, maxYear),
                      min: 1970,
                      max: DateTime.now().year.toDouble(),
                      divisions: DateTime.now().year - 1970,
                      onChanged: (RangeValues values) {
                        setModalState(() {
                          minYear = values.start;
                          maxYear = values.end;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SLIDER 2: MINIMUM SCORE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "MINIMUM IMDB SCORE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: subtleColor,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              scoreBadgeText,
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${minScore.toStringAsFixed(1)}+",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: subtleColor.withValues(alpha: 0.2),
                      thumbColor: Colors.white,
                      trackHeight: 6.0,
                      tickMarkShape: SliderTickMarkShape.noTickMark,
                    ),
                    child: Slider(
                      value: minScore,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      onChanged: (value) =>
                          setModalState(() => minScore = value),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- DROPDOWN: MAXIMUM RUNTIME ---
                  Text(
                    "MAXIMUM RUNTIME",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: subtleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      // ... rest of your existing runtime dropdown code
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: maxRuntime,
                        isExpanded: true,
                        dropdownColor: isDark
                            ? Colors.grey.shade900
                            : Colors.white,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: subtleColor,
                        ),
                        items:
                            [
                              'Any Length',
                              'Under 2.5 Hours',
                              'Under 2 Hours',
                              'Under 90 Mins',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (newValue) =>
                            setModalState(() => maxRuntime = newValue!),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SEGMENTED CHIPS: AGE RATING ---
                  Text(
                    "AGE RATING",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: subtleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => familyFriendly = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: familyFriendly
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark
                                        ? Colors.grey.shade900
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Family Friendly",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: familyFriendly
                                      ? Colors.white
                                      : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setModalState(() => familyFriendly = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              // THE FIX: Lights up red when 'familyFriendly' is false!
                              color: !familyFriendly
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark
                                        ? Colors.grey.shade900
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            // THE FIX: Turns the text white when active
                            child: Center(
                              child: Text(
                                "Anything Goes",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: !familyFriendly
                                      ? Colors.white
                                      : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- MULTI-SELECT: ORIGINAL LANGUAGE ---
                  Text(
                    "ORIGINAL LANGUAGE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: subtleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return StatefulBuilder(
                            builder: (context, setDialogState) {
                              final isDialogDark =
                                  Theme.of(context).brightness ==
                                  Brightness.dark;
                              final dialogBg = isDialogDark
                                  ? Colors.grey.shade900
                                  : Colors.white;
                              final dialogText = isDialogDark
                                  ? Colors.white
                                  : Colors.black87;
                              final dialogSubtle = isDialogDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400;

                              // THE FIX: Swapped AlertDialog for a custom Dialog to get perfect margin alignment!
                              return Dialog(
                                backgroundColor: dialogBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  // This 24px padding locks EVERYTHING (Title, List, Button) into perfect vertical alignment
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1. THE HEADER ROW
                                      Row(
                                        children: [
                                          Text(
                                            "Select Languages",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: dialogText,
                                            ),
                                          ),
                                          const Spacer(),
                                          // Clear All Button
                                          GestureDetector(
                                            onTap: () => setDialogState(
                                              () => selectedLanguages.clear(),
                                            ),
                                            child: Text(
                                              "Clear All",
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // THE FIX: The new 'X' Close Button
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: CircleAvatar(
                                              backgroundColor: isDialogDark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade100,
                                              radius: 14,
                                              child: Icon(
                                                Icons.close,
                                                color: dialogText,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // 2. THE CHECKLIST
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                            0.4,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: availableLanguages.length,
                                          itemBuilder: (context, index) {
                                            final lang =
                                                availableLanguages[index];
                                            return CheckboxListTile(
                                              // THE FIX: Removes the annoying default indentation from the checklist!
                                              contentPadding: EdgeInsets.zero,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              activeColor: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              checkColor: Colors.white,
                                              side: BorderSide(
                                                color: dialogSubtle.withValues(
                                                  alpha: 0.5,
                                                ),
                                                width: 1.5,
                                              ),
                                              title: Text(
                                                lang,
                                                style: TextStyle(
                                                  color: dialogText,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              value: selectedLanguages.contains(
                                                lang,
                                              ),
                                              onChanged: (bool? checked) {
                                                setDialogState(() {
                                                  if (checked == true) {
                                                    selectedLanguages.add(lang);
                                                  } else {
                                                    selectedLanguages.remove(
                                                      lang,
                                                    );
                                                  }
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // 3. THE "DONE" BUTTON
                                      // THE FIX: Styled to match the "Apply" button, but smaller (48px height vs 60px)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            elevation: 0,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text(
                                            "DONE",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                      setModalState(() {});
                    },
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedLanguages.isEmpty
                                ? "Any Language"
                                : "${selectedLanguages.length} Selected",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: subtleColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // THE FIX: Bumped up from 40 to 80 to get that perfect half-measure spacing!
                  const SizedBox(height: 80),

                  // --- SUBMIT BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final roomManagementService = ref.read(
                          roomManagementServiceProvider,
                        );
                        await roomManagementService
                            .updateFilterSettings(widget.roomCode, {
                              'minYear': minYear.toInt(),
                              'maxYear': maxYear.toInt(),
                              'minScore': minScore,
                              'maxRuntime': maxRuntime,
                              'familyFriendly': familyFriendly,
                              'languages': selectedLanguages,
                            });

                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text(
                        "APPLY TO ROOM",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor = theme.brightness == Brightness.light
        ? const Color(0xFFF8F9FA)
        : colorScheme.surface;

    ref.listen<AsyncValue<Room?>>(
      roomStreamProvider(widget.roomCode),
      _handleRoomUpdate,
    );

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          // NEW: The Host Settings Icon
          actions: [
            if (_isHost)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  color: colorScheme.primary,
                  splashColor: colorScheme.primary.withValues(alpha: 0.1),
                  onPressed: () {
                    _showHostSettingsModal();
                  },
                ),
              ),
          ],
        ),
        // We still use StreamBuilder to draw the UI live
        body: StreamBuilder<Room?>(
          // ignore: deprecated_member_use
          stream: ref.watch(roomStreamProvider(widget.roomCode).stream),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final Room? room = snapshot.data;
            if (room == null) {
              return const Center(child: CircularProgressIndicator());
            }
            // Convert room to data map for compatibility with existing UI
            final Map<String, dynamic> data = {
              'connectedPlayers': room.connectedPlayers,
              'playerProfiles': room.playerProfiles.map(
                (key, value) => MapEntry(key, value.toMap()),
              ),
            };
            final List<dynamic> connectedPlayers =
                data['connectedPlayers'] ?? [];
            final int playerCount = connectedPlayers.length;

            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Center(
                            child: Image.asset('assets/images/veto-logo.webp', height: 32),
                          ),
                          const SizedBox(height: 24),

                          // MOVED BACK: PEOPLE WAITING COUNT IS ON TOP
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                color: colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$playerCount People Waiting',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ROOM CODE CARD (Now sits below the count)
                          Container(
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.light
                                  ? Colors.white
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ROOM CODE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                widget.roomCode,
                                                style: TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w900,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () {
                                                  Clipboard.setData(
                                                    ClipboardData(
                                                      text: widget.roomCode,
                                                    ),
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Room code copied to clipboard!',
                                                      ),
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                  );
                                                },
                                                child: Icon(
                                                  Icons.copy,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              GestureDetector(
                                                onTap: () => _showQRCodeDialog(
                                                  widget.roomCode,
                                                ),
                                                child: Icon(
                                                  Icons.qr_code,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // PLAYER GRID
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.75,
                                ),
                            itemCount: playerCount,
                            itemBuilder: (context, index) {
                              final String targetDeviceId =
                                  connectedPlayers[index];

                              final Map<String, dynamic> playerProfiles =
                                  data['playerProfiles'] ?? {};

                              final Map<String, dynamic> currentProfile =
                                  playerProfiles[targetDeviceId] ??
                                  {
                                    'name': 'Player ${index + 1}',
                                    'avatar':
                                        availableAvatars[index %
                                            availableAvatars.length],
                                  };

                              bool isCurrentUser =
                                  targetDeviceId == widget.playerDeviceId;
                              String status = index == 2
                                  ? 'CHOOSING SNACKS...'
                                  : 'READY TO VETO';

                              return PlayerCard(
                                name: currentProfile['name']!,
                                imageUrl: currentProfile['avatar']!,
                                status: status,
                                isYou: isCurrentUser,
                                isHostView: _isHost,
                                targetDeviceId: targetDeviceId,
                                roomCode: widget.roomCode,
                                colorScheme: colorScheme,
                                brightness: theme.brightness,
                                onEditProfile: () => _showEditProfileDialog(
                                  currentProfile['name']!,
                                  currentProfile['avatar']!,
                                ),
                                onKick: () async {
                                  final roomManagementService = ref.read(
                                    roomManagementServiceProvider,
                                  );
                                  await roomManagementService.kickPlayer(
                                    widget.roomCode,
                                    targetDeviceId,
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),

                  // FOOTER CONTROLS
                  Container(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 32,
                      top: 16,
                    ),
                    decoration: BoxDecoration(color: bgColor),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isHost
                                  ? colorScheme.primary
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _isHost
                                ? () async {
                                    final roomManagementService = ref.read(
                                      roomManagementServiceProvider,
                                    );
                                    await roomManagementService
                                        .updateRoomStatus(
                                          widget.roomCode,
                                          'voting',
                                        );
                                  }
                                : null,
                            child: Text(
                              _isHost ? 'START SESSION' : 'WAITING FOR HOST...',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                              side: BorderSide(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _leaveRoom,
                            child: const Text(
                              'LEAVE ROOM',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
