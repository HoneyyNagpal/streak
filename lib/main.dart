import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HabitApp());
}

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBF8F3),
        fontFamily: 'Georgia',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E5C50),
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class Habit {
  String id;
  String name;
  int colorValue;
  List<String> completedDates; // stored as 'yyyy-MM-dd'

  Habit({
    required this.id,
    required this.name,
    required this.colorValue,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'completedDates': completedDates,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        colorValue: json['colorValue'],
        completedDates: List<String>.from(json['completedDates'] ?? []),
      );
}

String todayKey() {
  final now = DateTime.now();
  return dateKey(now);
}

String dateKey(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

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

const List<Color> habitColors = [
  Color(0xFF3E5C50), // deep sage
  Color(0xFFB5654A), // terracotta
  Color(0xFF4A6C8C), // muted blue
  Color(0xFFC9A15A), // ochre
  Color(0xFF8B5E83), // dusty plum
];

// ---------------------------------------------------------------------------
// HOME SCREEN
// ---------------------------------------------------------------------------

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
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('habits');
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      habits = decoded.map((e) => Habit.fromJson(e)).toList();
    }
    setState(() => loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(habits.map((h) => h.toJson()).toList());
    await prefs.setString('habits', raw);
  }

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
    final dayLabel = '${weekdayNames[today.weekday - 1]}, ${today.day} ${_monthName(today.month)}';

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
                    if (habits.isNotEmpty) _ProgressBar(habits: habits),
                  ],
                ),
              ),
            ),
            if (habits.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: _openAddSheet),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final habit = habits[index];
                      return _HabitTile(
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

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }
}

class _ProgressBar extends StatelessWidget {
  final List<Habit> habits;
  const _ProgressBar({required this.habits});

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
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E1D3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                height: 6,
                width: MediaQuery.of(context).size.width * 0.86 * ratio,
                decoration: BoxDecoration(
                  color: const Color(0xFF3E5C50),
                  borderRadius: BorderRadius.circular(10),
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

class _HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _HabitTile({
    required this.habit,
    required this.onToggle,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.completedDates.contains(todayKey());
    final color = Color(habit.colorValue);
    final streak = currentStreak(habit);

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFB5654A),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: done ? color.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: done ? color.withOpacity(0.3) : const Color(0xFFEDE7DB),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? color : Colors.transparent,
                    border: Border.all(
                      color: done ? color : const Color(0xFFCBC3B0),
                      width: 1.8,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF23291F),
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        streak == 1 ? '1 day streak' : '$streak day streak',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: color.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.black.withOpacity(0.25)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7DB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.eco_outlined, size: 32, color: Color(0xFF3E5C50)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nothing here yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF23291F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add the first thing you want to\nshow up for, every day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ADD / EDIT FORM SHEET (shared)
// ---------------------------------------------------------------------------

class HabitFormSheet extends StatefulWidget {
  final void Function(String name, Color color) onSubmit;
  final String? initialName;
  final Color? initialColor;

  const HabitFormSheet({
    super.key,
    required this.onSubmit,
    this.initialName,
    this.initialColor,
  });

  @override
  State<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends State<HabitFormSheet> {
  late final TextEditingController _controller;
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _selected = widget.initialColor ?? habitColors.first;
  }

  bool get isEditing => widget.initialName != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFFBF8F3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDD5C4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? 'Edit habit' : 'New habit',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF23291F),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: 'e.g. Read for 20 minutes',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEDE7DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFEDE7DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _selected, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: habitColors.map((c) {
                final isSelected = c.value == _selected.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 36 : 30,
                      height: isSelected ? 36 : 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black.withOpacity(0.15), width: 2)
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = _controller.text.trim();
                  if (name.isEmpty) return;
                  widget.onSubmit(name, _selected);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF23291F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing ? 'Save changes' : 'Add habit',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HABIT DETAIL SCREEN — calendar heatmap + stats + edit/delete
// ---------------------------------------------------------------------------

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
                _StatBlock(
                  label: 'Current streak',
                  value: '${currentStreak(habit)}',
                  color: color,
                ),
                const SizedBox(width: 14),
                _StatBlock(
                  label: 'Best streak',
                  value: '${longestStreak(habit)}',
                  color: color,
                ),
                const SizedBox(width: 14),
                _StatBlock(
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
              'Last 12 weeks - tap a day to toggle it',
              style: TextStyle(fontSize: 12.5, color: Colors.black.withOpacity(0.45)),
            ),
            const SizedBox(height: 16),
            _HeatmapGrid(
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

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEDE7DB)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.black.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeatmapGrid extends StatelessWidget {
  final Habit habit;
  final Color color;
  final void Function(DateTime date) onToggleDate;

  const _HeatmapGrid({
    required this.habit,
    required this.color,
    required this.onToggleDate,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    // Find the most recent Sunday to align columns as weeks (Mon-Sun rows).
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