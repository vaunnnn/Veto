# AGENTS.md

## Key Guidance

This file outlines critical repository-specific information to help agents quickly understand and work effectively within this codebase.

---

## Quick Repository Facts

- **Framework & Language**: Flutter & Dart
- **Feature-First Architecture**: Organizes components by feature rather than type. See `lib/features` for key app features like `auth`, `voting`, `resolution`, etc.
- **Important External Services**: `TMDB API` for movie data

---

## Commands and Setup

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd <project-folder>
flutter pub get
```

### 2. Environment Setup
Create a `.env` file in the root directory and include configuration keys:
```text
TMDB_API_KEY=your_secure_api_key_here
```
- Contact the project lead for secure keys.
- Ensure `.env` is added to the `.gitignore` file.

### 3. Run the App
Ensure an emulator or physical device is connected:
```bash
flutter run
```

---

## Architecture and Development Notes

- **Feature-First Folder Structure**:
  - Self-contained directories for each major feature under `lib/features`. For example:
    - `lib/features/auth/screens/`
    - `lib/features/voting/services/`
- Global app utilities or configs reside in `lib/core/`.

---

## Commit Conventions

Follow the commit message structure:
```text
<type>: <short summary>
```
- **Types:**
  - `feat:` New feature (e.g., `feat: add Google sign-in`)
  - `fix:` Bugfix (e.g., `fix: null pointer in movie details`)
  - `docs:` Documentation changes only (e.g., `docs: add TMDB setup guide`)
  - `chore:` Maintenance or dependencies (e.g., `chore: upgrade Dart SDK`)
  - `style:` Non-functional formatting changes.
  - `refactor:` Code adjustments that don't add/alter behavior.
  - `test:` Test additions or updates.

Examples:
- ✅ `feat: implement infinite scroll in home view`
- ✅ `fix: handle null release dates`

---

## Extensions or Style Checks
- Check the `lib/shared/widgets` before writing new UI elements to avoid duplication.