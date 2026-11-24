import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'local_task_service.dart';

/// Routes task operations to either the local store (when the user is
/// not signed in) or Supabase (when signed in).
///
/// On sign-in, any locally-created tasks are uploaded to Supabase and
/// the local cache is cleared.
class TaskService {
  final SupabaseClient _client;
  final LocalTaskService _local;
  final bool? _forceSignedIn;
  final String? _forceUserId;

  TaskService({
    SupabaseClient? client,
    LocalTaskService? local,
    this._forceSignedIn,
    this._forceUserId,
  })  : _client = client ?? Supabase.instance.client,
        _local = local ?? LocalTaskService();

  /// Whether the current user is authenticated.
  bool get isSignedIn => _forceSignedIn ?? _client.auth.currentUser != null;

  /// The current user's id, or `null` if not signed in.
  String? get userId => _forceUserId ?? _client.auth.currentUser?.id;

  Future<List<Task>> fetchTasks() async {
    if (!isSignedIn) {
      return _local.fetchTasks();
    }

    final userId = this.userId!;
    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('priority_order')
        .order('created_at');

    return response.map((row) => Task.fromMap(row)).toList();
  }

  Future<void> updateTaskCompletion({
    required String taskId,
    required bool completed,
  }) async {
    if (!isSignedIn) {
      return _local.updateTaskCompletion(
        taskId: taskId,
        completed: completed,
      );
    }

    await _client
        .from('tasks')
        .update({'completed': completed})
        .eq('id', taskId);
  }

  Future<void> deleteTask(String taskId) async {
    if (!isSignedIn) {
      return _local.deleteTask(taskId);
    }

    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    if (!isSignedIn) {
      return _local.addTask(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
      );
    }

    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'completed': false,
      'priority': priority,
      'priority_order': Task.priorityOrderFor(priority),
      'user_id': userId,
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
    if (!isSignedIn) {
      return _local.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
      );
    }

    final data = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'priority': priority,
      'priority_order': Task.priorityOrderFor(priority),
      'due_date': dueDate?.toIso8601String().split('T').first,
    };

    await _client.from('tasks').update(data).eq('id', taskId);
  }

  /// Uploads all locally-stored tasks to Supabase under the current user
  /// and clears the local cache. Call this right after a successful sign-in.
  Future<int> syncLocalTasks() async {
    if (!isSignedIn) return 0;

    final localTasks = await _local.drainTasks();
    if (localTasks.isEmpty) return 0;

    final userId = this.userId!;
    final rows = localTasks
        .map((t) => <String, dynamic>{
              'title': t.title,
              'description': t.description,
              'completed': t.completed,
              'priority': t.priority,
              'priority_order': t.priorityOrder ?? Task.priorityOrderFor(t.priority),
              'user_id': userId,
              if (t.dueDate != null)
                'due_date': t.dueDate!.toIso8601String().split('T').first,
            })
        .toList();

    await _client.from('tasks').insert(rows);
    return rows.length;
  }
}