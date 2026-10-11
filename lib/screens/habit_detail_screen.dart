import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../utils/streak_stats.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/heatmap_grid.dart';
import '../widgets/stat_block.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final void Function(DateTime date) onToggleDate;
  final void Function(String name, Color color) onEdit;
  final VoidCallback onDelete;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.onToggleDate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HabitFormSheet(
        initialName: widget.habit.name,
        initialColor: Color(widget.habit.colorValue),
        onSubmit: (name, color) {
          widget.onEdit(name, color);
          setState(() {});
        },
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFFBF8F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete this habit?'),
        content: Text('This removes "${widget.habit.name}" and all its history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: widget.onDelete,
            child: const Text('Delete', style: TextStyle(color: Color(0xFFB5654A))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habit = widget.habit;
    final color = Color(habit.colorValue);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F3),
        elevation: 0,
        foregroundColor: const Color(0xFF23291F),
        title: Text(habit.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditSheet,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatBlock(
                  label: 'Current streak',
                  value: '${currentStreak(habit)}',
                  color: color,
                ),
                const SizedBox(width: 14),
                StatBlock(
                  label: 'Best streak',
                  value: '${longestStreak(habit)}',
                  color: color,
                ),
                const SizedBox(width: 14),
                StatBlock(
                  label: 'Last 30 days',
                  value: '${(completionRateLastNDays(habit, 30) * 100).round()}%',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF23291F),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 12 weeks — tap a day to toggle it',
              style: TextStyle(fontSize: 12.5, color: Colors.black.withOpacity(0.45)),
            ),
            const SizedBox(height: 16),
            HeatmapGrid(
              habit: habit,
              color: color,
              onToggleDate: (date) {
                widget.onToggleDate(date);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
