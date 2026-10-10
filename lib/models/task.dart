class Task {
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

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      completed: map['completed'] as bool? ?? false,
      priority: map['priority']?.toString() ?? 'Medium',
      dueDate: map['due_date'] == null
          ? null
          : DateTime.tryParse(map['due_date'].toString()),
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
      priorityOrder: map['priority_order'] == null
          ? null
          : int.tryParse(map['priority_order'].toString()),
    );
  }
}