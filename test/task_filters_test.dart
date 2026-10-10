import 'package:flutter_test/flutter_test.dart';
import 'package:tasknest_flutter/models/task.dart';
import 'package:tasknest_flutter/utils/task_filters.dart';

Task _task({
  required String title,
  String description = '',
  bool completed = false,
  String priority = 'Medium',
}) {
  return Task(
    id: title,
    title: title,
    description: description,
    completed: completed,
    priority: priority,
  );
}

void main() {
  final tasks = [
    _task(title: 'Buy milk', completed: false, priority: 'High'),
    _task(title: 'Write report', completed: true, priority: 'High'),
    _task(title: 'Call dentist', completed: false, priority: 'Low'),
    _task(title: 'Plan trip', completed: true, priority: 'Medium'),
  ];

  group('Task.priorityOrder', () {
    test('maps High, Medium and Low to 3, 2 and 1', () {
      expect(Task.priorityOrderFor('High'), 3);
      expect(Task.priorityOrderFor('Medium'), 2);
      expect(Task.priorityOrderFor('Low'), 1);
    });

    test('falls back to the Medium value for unknown priorities', () {
      expect(Task.priorityOrderFor('Urgent'), 2);
      expect(Task.priorityOrderFor(''), 2);
    });
  });

  group('filterTasks', () {
    test('matches the title ignoring letter case', () {
      final result = filterTasks(
        tasks,
        query: 'BUY MILK',
        status: 'All',
        priority: 'All',
      );
      expect(result.map((t) => t.title), ['Buy milk']);
    });

    test('does not match the description', () {
      final result = filterTasks(
        [_task(title: 'Read', description: 'review the docs')],
        query: 'docs',
        status: 'All',
        priority: 'All',
      );
      expect(result, isEmpty);
    });

    test('returns all tasks when the query is blank', () {
      final result = filterTasks(tasks, query: '  ');
      expect(result.length, tasks.length);
    });

    test('keeps only pending tasks with status = Pending', () {
      final result = filterTasks(tasks, query: '', status: 'Pending');
      expect(result.map((t) => t.title), ['Buy milk', 'Call dentist']);
    });

    test('keeps only completed tasks with status = Completed', () {
      final result = filterTasks(tasks, query: '', status: 'Completed');
      expect(result.map((t) => t.title), ['Write report', 'Plan trip']);
    });

    test('keeps everything with status = All', () {
      final result = filterTasks(tasks, query: '', status: 'All');
      expect(result.length, tasks.length);
    });

    test('filters by High priority only', () {
      final result = filterTasks(tasks, query: '', priority: 'High');
      expect(result.map((t) => t.title), ['Buy milk', 'Write report']);
    });

    test('filters by Low priority only', () {
      final result = filterTasks(tasks, query: '', priority: 'Low');
      expect(result.map((t) => t.title), ['Call dentist']);
    });

    test('keeps everything with priority = All', () {
      final result = filterTasks(tasks, query: '', priority: 'All');
      expect(result.length, tasks.length);
    });

    test('combines search, status and priority together', () {
      final result = filterTasks(
        tasks,
        query: 'report',
        status: 'Completed',
        priority: 'High',
      );
      expect(result.map((t) => t.title), ['Write report']);

      final empty = filterTasks(
        tasks,
        query: 'milk',
        status: 'Completed',
        priority: 'High',
      );
      expect(empty, isEmpty);
    });

    test('returns an empty list for an empty task list', () {
      expect(filterTasks([], query: ''), isEmpty);
      expect(filterTasks([], query: 'x', status: 'Pending'), isEmpty);
    });
  });
}
