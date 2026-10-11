import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../utils/date_helpers.dart';

class DailyProgressBar extends StatelessWidget {
  final List<Habit> habits;
  const DailyProgressBar({super.key, required this.habits});

  @override
  Widget build(BuildContext context) {
    final key = todayKey();
    final done = habits.where((h) => h.completedDates.contains(key)).length;
    final total = habits.length;
    final ratio = total == 0 ? 0.0 : done / total;

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              // Track (the grey background bar)
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E1D3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Fill: a fraction of the track's own width, so 2/2 always
              // reaches the end no matter how wide or narrow the screen is.
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E5C50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$done/$total',
          style: TextStyle(
            fontSize: 13,
            color: Colors.black.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}