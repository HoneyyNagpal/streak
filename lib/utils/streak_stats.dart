import '../models/habit.dart';
import 'date_helpers.dart';

int currentStreak(Habit habit) {
  int streak = 0;
  DateTime cursor = DateTime.now();
  while (habit.completedDates.contains(dateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

int longestStreak(Habit habit) {
  if (habit.completedDates.isEmpty) return 0;
  final sorted = habit.completedDates.toList()..sort();
  final dates = sorted.map((s) {
    final parts = s.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }).toList();

  int longest = 1;
  int current = 1;
  for (int i = 1; i < dates.length; i++) {
    final diff = dates[i].difference(dates[i - 1]).inDays;
    if (diff == 1) {
      current++;
      if (current > longest) longest = current;
    } else if (diff > 1) {
      current = 1;
    }
  }
  return longest;
}

double completionRateLastNDays(Habit habit, int n) {
  final now = DateTime.now();
  int completed = 0;
  for (int i = 0; i < n; i++) {
    final d = now.subtract(Duration(days: i));
    if (habit.completedDates.contains(dateKey(d))) completed++;
  }
  return completed / n;
}
