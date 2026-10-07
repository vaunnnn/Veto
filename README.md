# VETO

### Find your next movie night pick, together.

Veto helps friends decide what to watch without the endless scrolling and back-and-forth. Create a room, invite your group, and swipe through movies tailored to your preferences. When everyone likes the same film, you have a match.

**[Click here to download Veto.](assets/apk/veto.apk?raw=true)**

## How it works

1. **Gather your group.** Create a room and share its code or QR code with friends.
2. **Set your preferences.** Choose genres, customize your profile, and let the host refine the movie pool.
3. **Swipe and decide.** Swipe right to like a movie or left to veto it. A shared pick appears when everyone agrees.

No account registration is needed. Use separate devices to try the group experience; an internet connection is required.

## Features

### Host a movie night

- Create a shared room and invite friends using a room code or QR code.
- Refine the movie pool by release year, minimum score, runtime, age rating, and original language.
- See who has joined, manage participants, and start the session.

### Join and vote

- Join a room by entering its code or scanning its QR code.
- Choose a display name and avatar, then select your preferred genres.
- Browse movie cards and vote with swipe gestures.
- Find a movie everyone wants to watch, with room activity and votes synced in real time.

## Screenshots

### From movie browsing to a shared pick

<p>
  <img src="assets/preview/movie-swiping.jpg" alt="Movie card with swipe controls for liking or vetoing a film" width="260" />
  <img src="assets/preview/movie-chosen.jpg" alt="The group's chosen movie after reaching a match" width="260" />
</p>

### Create or join a room

<p>
  <img src="assets/preview/landing-screen.jpg" alt="Veto welcome screen with options to create or join a room" width="260" />
  <img src="assets/preview/room.jpg" alt="Waiting room with participants and an invitation code" width="260" />
</p>

<details>
<summary>View joining, host settings, and profile customization</summary>

**Join a room**

<img src="assets/preview/join-room.jpg" alt="Join a movie night using a room code" width="280" />

**Host settings**

<img src="assets/preview/room-config.jpg" alt="Host filters for release year, minimum score, runtime, age rating, and language" width="280" />

**Customize your profile**

<img src="assets/preview/user-customization.jpg" alt="Profile customization with a display name and avatar selection" width="280" />

</details>

### Choose your genres

<img src="assets/preview/genre-selection.jpg" alt="Genre selection screen for choosing movie preferences" width="280" />

<details>
<summary>View the app introduction and how-to guide</summary>

**About Veto**

<img src="assets/preview/about.jpg" alt="About Veto and its group movie selection experience" width="280" />

**How to Veto**

<img src="assets/preview/how-to-veto.jpg" alt="In-app guide explaining how to join, swipe, and find a match" width="280" />

</details>

## Built with

- **Flutter & Dart** for the mobile interface.
- **Riverpod** for state management and dependency injection.
- **Firebase Cloud Firestore** for shared rooms and live voting updates.
- **The Movie Database (TMDB) API** for movie discovery, details, and posters.

The codebase uses Clean Architecture with shared domain models, repository interfaces, and business logic in `lib/core/`, alongside feature-based screens and widgets in `lib/features/`.
