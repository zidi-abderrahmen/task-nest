class Task {
  static const Map<String, int> priorityOrderValues = {
    'High': 3,
    'Medium': 2,
    'Low': 1,
  };

  /// Maps a priority label to its numeric sorting value.
  ///
  /// Unknown priorities fall back to the Medium value (2).
  static int priorityOrderFor(String priority) =>
      priorityOrderValues[priority] ?? 2;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.priority = 'Medium',
    this.dueDate,
    this.createdAt,
    this.priorityOrder,
  });

  final String id;
  final String title;
  final String description;
  final bool completed;
  final String priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final int? priorityOrder;

  /// Normalizes any date string to a date-only `DateTime` (local midnight).
  ///
  /// Supabase stores due dates as `yyyy-MM-dd`, but timestamps (`T...`) are
  /// tolerated as well so that due-date dates never shift across timezones.
  static DateTime? _parseDueDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      completed: map['completed'] as bool? ?? false,
      priority: map['priority']?.toString() ?? 'Medium',
      dueDate: _parseDueDate(map['due_date']),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      priorityOrder: map['priority_order'] == null
          ? null
          : int.tryParse(map['priority_order'].toString()),
    );
  }
}
