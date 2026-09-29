# Streak

A minimal, calendar-driven habit tracker built in Flutter.

## Features

- Add, edit, and delete daily habits with custom colors
- Track completion with a single tap
- Automatic streak calculation (current streak + all-time best streak)
- 12-week calendar heatmap per habit tap any past day to mark it done or undone
- Completion rate over the last 30 days
- Local persistence via `shared_preferences`, no backend required

## Stack

- Flutter / Dart
- `shared_preferences` for local storage
- No external state management library — built with native `StatefulWidget` + `setState`

## Running locally

```bash
flutter pub get
flutter run -d chrome   # or any connected device
```

## Screens

- **Today** - today's habits with quick toggle and daily progress bar
- **Habit Detail** - streak stats, completion rate, and a full history heatmap with edit/delete