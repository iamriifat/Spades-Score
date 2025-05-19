# Spades Score (Bridge Scorer)

A Flutter app for scoring Spades (or Bridge) games, with user authentication and game history, built using Firebase.

## Features

- User authentication (Firebase Auth, with dummy mode for development)
- Start, play, and score Spades games
- View game history and statistics
- User profile management
- Modern, responsive UI

## Project Structure

```
lib/
  main.dart                # App entry point, provider setup, navigation
  models/
    game.dart              # Game and score data model
    user_profile.dart      # User profile data model
  providers/
    game_provider.dart     # Game state management
    user_provider.dart     # User/auth state management
  screens/
    auth_screen.dart       # Login/Signup UI
    home_screen.dart       # Dashboard UI
    game_screen.dart       # Game play/scoring UI
    history_screen.dart    # Game history UI
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase project](https://firebase.google.com/)
- Android Studio or VS Code

### Setup

1. **Clone the repository:**
   ```sh
   git clone <your-repo-url>
   cd <project-folder>
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
   - Make sure your Firebase project has Authentication and Firestore enabled.

4. **Run the app:**
   ```sh
   flutter run
   ```

## Development Notes

- If you encounter reCAPTCHA issues during development, you can use the dummy authentication mode in `UserProvider`.
- The app uses the `provider` package for state management.

## Folder Overview

- `models/` - Data models for users and games.
- `providers/` - State management for user and game data.
- `screens/` - UI screens for authentication, home, game, and history.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](LICENSE)
