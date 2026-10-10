import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

class TaskService {
  final SupabaseClient _client;

  TaskService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<Task>> fetchTasks() async {
    final response = await _client
        .from('tasks')
        .select()
        .order('priority_order')
        .order('created_at');

    return response.map((row) => Task.fromMap(row)).toList();
  }

  Future<void> updateTaskCompletion({
    required String taskId,
    required bool completed,
  }) async {
    await _client
        .from('tasks')
        .update({'completed': completed})
        .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    await _client
        .from('tasks')
        .delete()
        .eq('id', taskId);
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    final priorityOrder = {
      'High': 3,
      'Medium': 2,
      'Low': 1,
    }[priority] ?? 2;
    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'completed': false,
      'priority': priority,
      'priority_order': priorityOrder,
    };

    if (dueDate != null) {
      data['due_date'] = dueDate.toIso8601String().split('T').first;
    }

    await _client.from('tasks').insert(data);
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    final priorityOrder = {
      'Low': 1,
      'Medium': 2,
      'High': 3,
    }[priority] ?? 2;

    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority,
      'priority_order': priorityOrder,
      'due_date': dueDate?.toIso8601String().split('T').first,
    };

    await _client
        .from('tasks')
        .update(data)
        .eq('id', taskId);
  }
}