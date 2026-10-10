import 'package:flutter_test/flutter_test.dart';
import 'package:tasknest_flutter/models/task.dart';
import 'package:tasknest_flutter/models/task_statistics.dart';

Task _task({bool completed = false}) {
  return Task(id: 't', title: 'Title', completed: completed);
}

void main() {
  group('TaskStatistics.fromTasks', () {
    test('returns zero statistics for an empty task list', () {
      final stats = TaskStatistics.fromTasks([]);

      expect(stats.total, 0);
      expect(stats.completed, 0);
      expect(stats.pending, 0);
      expect(stats.completionRate, 0.0);
      expect(stats.completionPercentage, 0);
    });

    test('counts all tasks as pending when nothing is completed', () {
      final stats = TaskStatistics.fromTasks([
        _task(completed: false),
        _task(completed: false),
      ]);

      expect(stats.total, 2);
      expect(stats.completed, 0);
      expect(stats.pending, 2);
      expect(stats.completionRate, 0.0);
    });

    test('counts all tasks as completed when everything is done', () {
      final stats = TaskStatistics.fromTasks([
        _task(completed: true),
        _task(completed: true),
        _task(completed: true),
      ]);

      expect(stats.total, 3);
      expect(stats.completed, 3);
      expect(stats.pending, 0);
      expect(stats.completionRate, 1.0);
      expect(stats.completionPercentage, 100);
    });

    test('computes a mixed completion rate', () {
      final stats = TaskStatistics.fromTasks([
        _task(completed: true),
        _task(completed: true),
        _task(completed: false),
        _task(completed: false),
      ]);

      expect(stats.total, 4);
      expect(stats.completed, 2);
      expect(stats.pending, 2);
      expect(stats.completionRate, 0.5);
      expect(stats.completionPercentage, 50);
    });

    test('rounds the completion percentage', () {
      final stats = TaskStatistics.fromTasks([
        _task(completed: true),
        _task(completed: true),
        _task(completed: false),
      ]);

      expect(stats.completionRate, closeTo(2 / 3, 0.0001));
      expect(stats.completionPercentage, 67);
    });
  });
}
