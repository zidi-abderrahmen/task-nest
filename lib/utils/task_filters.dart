import '../models/task.dart';

enum TaskStatusFilter {
  all('All'),
  pending('Pending'),
  completed('Completed');

  const TaskStatusFilter(this.label);
  final String label;

  bool matches(Task task) => switch (this) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.pending => !task.completed,
        TaskStatusFilter.completed => task.completed,
      };
}

enum TaskPriorityFilter {
  all('All'),
  high('High'),
  medium('Medium'),
  low('Low');

  const TaskPriorityFilter(this.label);
  final String label;

  bool matches(Task task) =>
      this == TaskPriorityFilter.all || task.priority == label;
}

List<Task> filterTasks(
  List<Task> tasks, {
  String query = '',
  TaskStatusFilter status = TaskStatusFilter.all,
  TaskPriorityFilter priority = TaskPriorityFilter.all,
}) {
  final q = query.trim().toLowerCase();
  return tasks.where((task) {
    final matchesQuery = q.isEmpty ||
        task.title.toLowerCase().contains(q);
    return matchesQuery && status.matches(task) && priority.matches(task);
  }).toList();
}