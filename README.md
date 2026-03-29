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
    │   ├── constants/          # API keys, endpoint URLs, standard UI padding
    │   ├── theme/              # Colors, text styles, dark/light mode setup
    │   └── utils/              # Helper functions (e.g., date formatters)
    │
    ├── features/               # The core functionalities of your app
    │   ├── auth/               # Everything related to signing in
    │   │   ├── screens/        # Login/Signup UI
    │   │   └── services/       # Auth logic (Firebase/Supabase)
    │   │
    │   ├── movies/             # Everything related to TMDB data
    │   │   ├── models/         # Dart classes representing Movie data
    │   │   ├── screens/        # Home screen, Movie Detail screen
    │   │   ├── widgets/        # UI pieces specific to movies (e.g., MovieCard)
    │   │   └── services/       # The code that actually calls the TMDB API
    │   │
    │   └── favorites/          # Logic for saving movies to the database
    │
    ├── shared/                 # Reusable UI components used across the whole app
    │   └── widgets/            # Custom buttons, loading spinners, error dialogs
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
