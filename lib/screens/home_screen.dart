import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';
import '../utils/date_helpers.dart';
import '../widgets/daily_progress_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/habit_form_sheet.dart';
import '../widgets/habit_tile.dart';
import 'habit_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> habits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    habits = await HabitStorage.load();
    setState(() => loading = false);
  }

  Future<void> _save() => HabitStorage.save(habits);

  void _toggleToday(Habit habit) {
    final key = todayKey();
    setState(() {
      if (habit.completedDates.contains(key)) {
        habit.completedDates.remove(key);
      } else {
        habit.completedDates.add(key);
      }
    });
    _save();
  }

  void _addHabit(String name, Color color) {
    setState(() {
      habits.add(Habit(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        colorValue: color.value,
      ));
    });
    _save();
  }

  void _editHabit(Habit habit, String newName, Color newColor) {
    setState(() {
      habit.name = newName;
      habit.colorValue = newColor.value;
    });
    _save();
  }

  void _deleteHabit(Habit habit) {
    setState(() => habits.removeWhere((h) => h.id == habit.id));
    _save();
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HabitFormSheet(onSubmit: _addHabit),
    );
  }

  void _openHabitDetail(Habit habit) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(
          habit: habit,
          onToggleDate: (date) {
            setState(() {
              final key = dateKey(date);
              if (habit.completedDates.contains(key)) {
                habit.completedDates.remove(key);
              } else {
                habit.completedDates.add(key);
              }
            });
            _save();
          },
          onEdit: (name, color) => _editHabit(habit, name, color),
          onDelete: () {
            _deleteHabit(habit);
            Navigator.pop(context);
          },
        ),
      ),
    );
    setState(() {}); // refresh home after returning from detail
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final today = DateTime.now();
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayLabel = '${weekdayNames[today.weekday - 1]}, ${today.day} ${monthName(today.month)}';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.45),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Today',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF23291F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (habits.isNotEmpty) DailyProgressBar(habits: habits),
                  ],
                ),
              ),
            ),
            if (habits.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(onAdd: _openAddSheet),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = habits[index];
                      return HabitTile(
                        habit: habit,
                        onToggle: () => _toggleToday(habit),
                        onDelete: () => _deleteHabit(habit),
                        onTap: () => _openHabitDetail(habit),
                      );
                    },
                    childCount: habits.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: const Color(0xFF23291F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New habit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
