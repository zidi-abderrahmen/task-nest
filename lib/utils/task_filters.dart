import '../models/task.dart';

/// Filters a list of tasks by search text, status, and priority.
///
/// - [query] is matched against the task title, ignoring letter case.
/// - [status] accepts `All`, `Pending`, or `Completed`.
/// - [priority] accepts `All`, `High`, `Medium`, or `Low`.
/// - All three criteria must match for a task to be kept.
List<Task> filterTasks(
  List<Task> tasks, {
  required String query,
  String status = 'All',
  String priority = 'All',
}) {
  final normalizedQuery = query.trim().toLowerCase();

  return tasks.where((task) {
    final matchesSearch = task.title.toLowerCase().contains(normalizedQuery);

    final matchesStatus =
        status == 'All' ||
        (status == 'Pending' && !task.completed) ||
        (status == 'Completed' && task.completed);

    final matchesPriority = priority == 'All' || task.priority == priority;

    return matchesSearch && matchesStatus && matchesPriority;
  }).toList();
}
