# Movie Tracking App - Developer Guide

## Project Overview

Welcome to the repository for our cross-platform movie tracking application. This project is built using **Flutter** and **Dart**, utilizing **The Movie Database (TMDB) REST API** for fetching rich movie data. 

---

## Feature-First Architecture

This project strictly adheres to a **Feature-First Architecture** rather than a traditional layer-first approach. 

Instead of grouping files by their type (e.g., putting all models in one folder and all screens in another), we group files by the **feature** they belong to. This ensures that a developer working on the "Authentication" feature does not need to hunt through the entire project to find the relevant screens, state management, and API calls. Everything related to a specific feature lives in its own self-contained folder.

### Directory Structure

    lib/
    │
    ├── core/                   # App-wide configurations
    │   ├── constants/          # API keys, TMDB URLs, standard UI padding
    │   ├── theme/              # Colors, typography, swipe card themes
    │   └── utils/              # Helper functions (e.g., room code generators)
    │
    ├── features/               # Veto's core functionalities
    │   ├── auth/               # Headless authentication
    │   │   └── services/       # Anonymous login logic (No screens needed!)
    │   │
    │   ├── rooms/              # Lobby and connection logic
    │   │   ├── models/         # Room and Player data structures
    │   │   ├── screens/        # Join/Create screen, Waiting Room screen
    │   │   └── services/       # Real-time database syncing for room state
    │   │
    │   ├── voting/             # The core game loop
    │   │   ├── models/         # Movie data from TMDB
    │   │   ├── screens/        # Genre Selection, Swipe Deck screen
    │   │   ├── widgets/        # Tinder-style swipe cards, progress bars
    │   │   └── services/       # TMDB API calls, real-time vote casting
    │   │
    │   └── resolution/         # Match results
    │       └── screens/        # The "Match Found!" screen, re-roll options
    │
    ├── shared/                 # Reusable UI components
    │   └── widgets/            # Primary buttons, text inputs for room codes
    │
    └── main.dart               # The entry point that initializes the app

---

### Core Folder (`lib/core/`)

The **Core** directory is the foundational layer of the app. It does not contain UI screens or feature-specific logic. Instead, it houses the globally required configurations.

- **Constants:** Store static variables like `AppColors.primaryBlue` or `ApiConstants.tmdbBaseUrl`. Never hardcode strings or colors directly into your UI files.
- **Theme:** Centralize all Material Design theme configurations here so the app looks identical regardless of who coded the screen.
- **Utils:** Place global helper functions here, such as a function that converts a TMDB API date string into a readable format like "October 24, 2023".

### Features Folder (`lib/features/`)

The **Features** directory is where 90% of your daily development will occur. Each folder here represents an isolated module.

- **Autonomy:** If you delete the `auth/` folder, the rest of the app (like fetching movies) should ideally not crash. 
- **Internal Widgets:** If a UI component (like a `MoviePosterCard`) is only ever used inside the Movie feature, put it in `lib/features/movies/widgets/`. Do not clutter the global shared folder with feature-specific UI.

### Shared Folder (`lib/shared/`)

The **Shared** directory acts as our global UI library.

- **Reusability:** If you create a highly customized `PrimarySubmitButton` that will be used on the Login screen, the Settings screen, and the Edit Profile screen, it belongs here.
- **Consistency:** Always check the `shared/widgets/` folder before building a new button or loading spinner to prevent duplicating code.

---

## Getting Started for New Developers

Follow these steps to get your local environment running.

### 1. Clone & Install

First, pull the repository and download all required Dart packages.

    git clone <repository-url>
    cd <project-folder>
    flutter pub get

### 2. Environment Variables (.env)

For security reasons, our TMDB API keys and backend configuration URLs are not tracked in Git. 

- Create a file named `.env` in the root of the project (at the same level as `pubspec.yaml`).
- Reach out to the project lead for the secure keys.
- Add the keys to the file as follows:

    TMDB_API_KEY=your_secure_api_key_here

> **CRITICAL WARNING:** Never commit the `.env` file. Double-check that it is listed in your `.gitignore` before making your first commit. If an API key is leaked to GitHub, TMDB will automatically revoke it and break the app for the entire team.

### 3. Run the App

Ensure you have an emulator running or a physical device connected, then launch the app.

    flutter run

---

## Security Notice

### API Key Security
The `.env` file containing API keys has been removed from git history. However, if your keys were previously committed, they may be compromised. Take immediate action:

1. **Regenerate API Keys:**
   - TMDB: Visit https://www.themoviedb.org/settings/api to generate a new key
   - Firebase: Regenerate API keys in Firebase Console

2. **Update Local Environment:**
   - Rename `.env` to `.env.backup`
   - Copy `.env.local.example` to `.env.local`
   - Fill in your new API keys
   - Update `main.dart` to load `.env.local` instead of `.env`

3. **Verify Git History:**
   ```bash
   git log --all --oneline -- .env
   ```
   If any commits show `.env`, consider rewriting git history or rotating keys.

### Architecture Security Improvements
The new Clean Architecture separates backend logic from UI, providing:
- No direct Firebase calls in screens
- API keys only accessed via service layer
- Business logic isolated from presentation layer

---

## Commit Message Convention

Every commit message must be structured as follows:
`<type>: <short summary>`

### Commit Message Types :
* **`feat:`** A new feature for the user (e.g., `feat: add Google sign-in button`)
* **`fix:`** A bug fix (e.g., `fix: resolve crash on movie detail screen`)
* **`chore:`** Routine tasks, maintenance, or updating dependencies (e.g., `chore: update flutter SDK to 3.19.0`)
* **`docs:`** Changes to documentation or README only (e.g., `docs: add commit convention guide`)
* **`style:`** Formatting, missing semi-colons, linting fixes—no logic changes (e.g., `style: format auth_service.dart`)
* **`refactor:`** Rewriting code without changing its behavior or adding features (e.g., `refactor: extract movie card into shared widget`)
* **`test:`** Adding missing tests or correcting existing ones (e.g., `test: add unit tests for tmdb api parser`)

### Examples of Good Commits:
✅ `feat: implement infinite scrolling on home screen`
✅ `fix: handle null release dates from TMDB API`
✅ `chore: add flutter_dotenv package`
