# Streak

A minimal habit tracker built with Flutter. Track daily habits, watch your streaks grow, and look back over the last 12 weeks on a calendar heatmap.

## Features

- Add, edit and delete habits, each with its own color
- Mark a habit done for today with one tap, with a daily progress bar on the home screen
- Current streak and best-ever streak for every habit
- Completion rate over the last 30 days
- 12-week calendar heatmap per habit, tap any past day to mark it done or undone
- Swipe to delete on the home screen, with a confirmation dialog on the detail screen
- Everything is saved locally and survives restarts, no account or backend needed

## Project structure

```
lib/
  main.dart                       App entry point and theme
  models/
    habit.dart                    Habit model and JSON conversion
  services/
    habit_storage.dart            Saving and loading habits (SharedPreferences)
  utils/
    date_helpers.dart             Date keys and month names
    streak_stats.dart             Current streak, best streak, completion rate
  constants/
    habit_colors.dart             Color palette for habits
  screens/
    home_screen.dart              Today's habits, add and toggle
    habit_detail_screen.dart      Stats, heatmap, edit and delete
  widgets/
    daily_progress_bar.dart
    habit_tile.dart
    empty_state.dart
    habit_form_sheet.dart         Shared add and edit form
    stat_block.dart
    heatmap_grid.dart
```

The data logic (models, storage, streak calculations) is kept separate from the UI, so the streak functions are plain Dart and easy to unit test.

## How it works

- Each habit stores its completed days as `yyyy-MM-dd` strings. All stats are derived from that one list.
- The current streak counts back from today while consecutive days are marked. The best streak sorts all completed dates and finds the longest run of consecutive days.
- The whole habit list is serialized to JSON and stored under a single SharedPreferences key.
- State is managed with `StatefulWidget` and `setState`, with callbacks passed down to child screens. This is enough for two screens, and the next step for a larger app would be Provider or Riverpod.

## Tech stack

- Flutter and Dart
- `shared_preferences` for local storage
- Material 3 with a custom theme

## Getting started

```bash
git clone https://github.com/HoneyyNagpal/streak.git
cd streak
flutter pub get
flutter run -d chrome
```

You can replace `chrome` with any connected device or emulator. So far the app has been developed and tested on Chrome.

## Roadmap

- Unit tests for the streak functions and widget tests for the add and toggle flows
- Daily reminder notifications
- Cloud sync so habits survive a change of phone
- Habits that are not daily, such as three times a week
- Dark mode