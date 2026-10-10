import 'package:flutter_test/flutter_test.dart';
import 'package:tasknest_flutter/models/task.dart';

void main() {
  group('Task.fromMap', () {
    test('parses every column of a complete row', () {
      final task = Task.fromMap({
        'id': '9f8c0b42-4a1e-4f5d-9b3a-2c1e0f7a6b5d',
        'title': 'Buy groceries',
        'description': 'Milk, bread and eggs',
        'completed': true,
        'priority': 'High',
        'due_date': '2026-10-15',
        'created_at': '2026-10-01T09:30:00.000Z',
        'priority_order': 3,
      });

      expect(task.id, '9f8c0b42-4a1e-4f5d-9b3a-2c1e0f7a6b5d');
      expect(task.title, 'Buy groceries');
      expect(task.description, 'Milk, bread and eggs');
      expect(task.completed, isTrue);
      expect(task.priority, 'High');
      expect(task.dueDate, DateTime(2026, 10, 15));
      expect(task.createdAt, DateTime.utc(2026, 10, 1, 9, 30));
      expect(task.priorityOrder, 3);
    });

    test('applies defaults when nullable columns are missing', () {
      final task = Task.fromMap({'id': 'abc', 'title': 'Hello'});

      expect(task.description, '');
      expect(task.completed, isFalse);
      expect(task.priority, 'Medium');
      expect(task.dueDate, isNull);
      expect(task.createdAt, isNull);
      expect(task.priorityOrder, isNull);
    });

    test('handles null title by falling back to an empty string', () {
      final task = Task.fromMap({'id': '1', 'title': null});
      expect(task.title, '');
    });

    test('parses due date from a full timestamp string', () {
      final task = Task.fromMap({
        'id': '1',
        'title': 'x',
        'due_date': '2026-12-31T23:59:59.000Z',
      });
      expect(task.dueDate, isNotNull);
      expect(task.dueDate, DateTime(2026, 12, 31));
    });

    test('leaves due date null when the value is not a valid date', () {
      final task = Task.fromMap({
        'id': '1',
        'title': 'x',
        'due_date': 'not-a-date',
      });
      expect(task.dueDate, isNull);
    });

    test('parses priority_order even when it arrives as a string', () {
      final task = Task.fromMap({
        'id': '1',
        'title': 'x',
        'priority_order': '2',
      });
      expect(task.priorityOrder, 2);
    });

    test('keeps a numeric priority_order intact', () {
      final task = Task.fromMap({'id': '1', 'title': 'x', 'priority_order': 1});
      expect(task.priorityOrder, 1);
    });

    test('parses completed even when it arrives as a boolean', () {
      final task = Task.fromMap({'id': '1', 'title': 'x', 'completed': true});
      expect(task.completed, isTrue);
    });
  });
}
