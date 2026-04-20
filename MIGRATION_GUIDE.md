# Backend/Frontend Separation Migration Guide

## Overview
This guide outlines the steps to migrate from the current mixed architecture to a Clean Architecture with proper separation of backend and frontend logic. The new architecture uses Riverpod for state management and follows the Repository pattern.

## New Architecture Structure
```
lib/
├── core/
│   ├── domain/
│   │   ├── entities/          # Data models (Room, Movie, Vote, etc.)
│   │   ├── repositories/      # Abstract repository interfaces
│   │   └── services/          # Business logic services
│   ├── data/
│   │   ├── repositories/      # Concrete implementations (Firebase, TMDB)
│   │   └── datasources/       # (Optional) Direct data sources
│   ├── providers/             # Riverpod providers
│   └── themes/                # UI themes
├── features/                  # UI components only (presentation layer)
└── main.dart
```

## Completed Work

### 1. Added Dependencies
- `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` for state management
- `build_runner` for code generation

### 2. Created Entity Models
- `Movie` - TMDB movie data
- `MovieDetails` - Extended movie details
- `Room` - Room state with Firestore mapping
- `PlayerProfile` - Player information
- `FilterSettings` - Room filter settings
- `Vote` - Voting data per movie
- `Match` - Match results

### 3. Created Repository Layer
**Abstract Interfaces:**
- `RoomRepository` - Room operations
- `MovieRepository` - TMDB API operations
- `VotingRepository` - Voting operations

**Concrete Implementations:**
- `FirebaseRoomRepository` - Firebase Firestore room management
- `TmdbMovieRepository` - TMDB API integration
- `FirebaseVotingRepository` - Firebase voting logic

### 4. Created Service Layer
- `RoomManagementService` - Room business logic
- `VotingService` - Voting business logic
- `MovieFilterService` - TMDB query building with filters

### 5. Created Riverpod Providers
- **Repository providers**: `roomRepositoryProvider`, `movieRepositoryProvider`, `votingRepositoryProvider`
- **Service providers**: `roomManagementServiceProvider`, `votingServiceProvider`, `movieFilterServiceProvider`
- **State providers**: `roomStreamProvider`, `voteStreamProvider`, `currentRoomCodeProvider`

### 6. Updated Main App
- Wrapped app with `ProviderScope`
- Updated `DeviceIdService` to be non-static

## Migration Steps for Each Screen

### Step 1: Update Imports
Replace Firebase/TMDB direct calls with repository/service injections.

### Step 2: Convert to Consumer Widget
Change `StatefulWidget` to `ConsumerWidget` or `ConsumerStatefulWidget`.

### Step 3: Use Providers
Access services and state via `ref.watch(provider)`.

### Step 4: Remove Business Logic from UI
Extract Firebase calls and complex logic to services.

## Example: Refactoring Landing Screen

### Before:
```dart
class _LandingScreenState extends State<LandingScreen> {
  bool _isCreatingRoom = false;
  final RoomService _roomService = RoomService();
  
  Future<void> _createRoom() async {
    final deviceId = await DeviceIdService.id;
    String newRoomCode = await _roomService.createRoom(deviceId);
    // Navigation logic...
  }
}
```

### After:
```dart
class LandingScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomManagementService = ref.watch(roomManagementServiceProvider);
    final deviceIdService = ref.watch(deviceIdServiceProvider);
    
    Future<void> _createRoom() async {
      final deviceId = await deviceIdService.getDeviceId();
      final roomCode = await roomManagementService.createRoom(deviceId);
      // Navigation logic...
    }
    
    return Scaffold(...);
  }
}
```

## Screen-by-Screen Migration

### 1. Landing Screen (Priority: High)
- Replace `RoomService` with `roomManagementServiceProvider`
- Replace `DeviceIdService.id` with `deviceIdServiceProvider`

### 2. Join Room Screen (Priority: High)
- Same as landing screen
- Use `roomStreamProvider` to watch room state

### 3. Waiting Room Screen (Priority: High)
- **Complex screen with 1400+ lines**
- Extract host settings logic to `RoomManagementService`
- Use `roomStreamProvider` for real-time updates
- Move filter logic to `MovieFilterService`

### 4. Swipe Deck Screen (Priority: High)
- **Core voting logic with 870+ lines**
- Extract `_fetchMovies()` to `MovieFilterService`
- Extract `_castVote()` to `VotingService`
- Use `voteStreamProvider` for real-time vote updates

### 5. Genre Selection Screen (Priority: Medium)
- Extract room listening logic
- Use `roomStreamProvider`

## Testing Strategy
1. **Unit Tests**: Test repositories and services in isolation
2. **Provider Tests**: Test Riverpod providers
3. **Widget Tests**: Test UI components with mocked providers

## Security Improvements
1. **API Key Security**: `.env` file removed from git history (create `.env.local` from template)
2. **Key Rotation**: Regenerate TMDB and Firebase API keys
3. **Environment Validation**: Add validation for required env variables

## Quality Assurance
Run these commands after each migration step:
```bash
flutter analyze
dart format .
flutter test
```

## Benefits of New Architecture

### 1. Security
- Backend logic isolated from UI
- API keys managed via services
- No direct Firebase calls in screens

### 2. Maintainability
- Clear separation of concerns
- Business logic in testable services
- UI components focused on presentation

### 3. Testability
- Services can be unit tested
- Repositories can be mocked
- UI tests with fake providers

### 4. Scalability
- Easy to add new data sources
- Simple to swap Firebase with another backend
- Clean addition of new features

## Next Steps

### Immediate (Week 1)
1. Migrate Landing Screen (example provided)
2. Migrate Join Room Screen
3. Write unit tests for services

### Short-term (Week 2)
1. Migrate Waiting Room Screen (break into smaller widgets)
2. Migrate Swipe Deck Screen
3. Set up CI/CD with automated tests

### Long-term (Week 3-4)
1. Add error handling and loading states
2. Implement proper error reporting
3. Add analytics and monitoring
4. Performance optimization

## Rollback Plan
If issues arise during migration:
1. Keep old service classes alongside new ones
2. Use feature flags to switch between implementations
3. Gradual migration per screen
4. Comprehensive testing before full switch

## Support
For questions or issues during migration, refer to:
1. Riverpod documentation: https://riverpod.dev
2. Clean Architecture examples in the codebase
3. Example migrated screens (see `features/` for reference implementations)

---

**Note**: This migration maintains 100% backward compatibility. Old screens continue to work while new architecture is incrementally adopted.