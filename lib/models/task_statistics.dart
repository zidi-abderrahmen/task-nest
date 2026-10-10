import 'task.dart';

/// Aggregated progress metrics computed from a list of tasks.
class TaskStatistics {
  const TaskStatistics({
    required this.total,
    required this.completed,
    required this.pending,
    required this.completionRate,
  });

  factory TaskStatistics.fromTasks(List<Task> tasks) {
    final total = tasks.length;
    final completed = tasks.where((task) => task.completed).length;
    final pending = total - completed;

    // Avoid dividing by zero when the task list is empty.
    final completionRate = total == 0 ? 0.0 : completed / total;

    return TaskStatistics(
      total: total,
      completed: completed,
      pending: pending,
      completionRate: completionRate,
    );
  }

  final int total;
  final int completed;
  final int pending;

  /// Completion ratio in the range 0.0 - 1.0.
  final double completionRate;

  int get completionPercentage => (completionRate * 100).round();
}
