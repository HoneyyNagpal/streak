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
