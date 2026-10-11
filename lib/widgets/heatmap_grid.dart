import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../utils/date_helpers.dart';

/// 12-week calendar heatmap. Each column is one week (Mon to Sun).
class HeatmapGrid extends StatelessWidget {
  final Habit habit;
  final Color color;
  final void Function(DateTime date) onToggleDate;

  const HeatmapGrid({
    super.key,
    required this.habit,
    required this.color,
    required this.onToggleDate,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Find the most recent Monday so each column lines up as Mon..Sun.
    final daysSinceMonday = today.weekday - 1;
    final thisMonday = today.subtract(Duration(days: daysSinceMonday));
    const weeks = 12;
    final firstMonday = thisMonday.subtract(const Duration(days: 7 * (weeks - 1)));

    // Build columns: each column is one week, each column has 7 cells (Mon..Sun)
    List<Widget> columns = [];
    for (int w = 0; w < weeks; w++) {
      final weekStart = firstMonday.add(Duration(days: 7 * w));
      List<Widget> cells = [];
      for (int d = 0; d < 7; d++) {
        final day = weekStart.add(Duration(days: d));
        final isFuture = day.isAfter(today);
        final done = habit.completedDates.contains(dateKey(day));
        cells.add(
          Padding(
            padding: const EdgeInsets.all(2),
            child: GestureDetector(
              onTap: isFuture ? null : () => onToggleDate(day),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isFuture
                      ? Colors.transparent
                      : (done ? color : const Color(0xFFEDE7DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      }
      columns.add(Column(children: cells));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(children: columns),
    );
  }
}
