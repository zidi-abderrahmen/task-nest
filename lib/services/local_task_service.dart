import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

/// Stores tasks locally on the device when the user is not signed in.
///
/// Tasks are persisted as a JSON array under a single SharedPreferences key.
/// Each local task gets a generated UUID-like id so it can be tracked and
/// synced to Supabase once the user signs in.
class LocalTaskService {
  static const _storageKey = 'local_tasks';

  Future<List<Task>> fetchTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Task.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _saveTasks(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => _taskToMap(t)).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addTask({
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    final tasks = await fetchTasks();
    final now = DateTime.now();
    final task = Task(
      id: _generateId(),
      title: title.trim(),
      description: description.trim(),
      completed: false,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      priorityOrder: Task.priorityOrderFor(priority),
    );
    tasks.add(task);
    await _saveTasks(tasks);
  }

  Future<void> updateTaskCompletion({
    required String taskId,
    required bool completed,
  }) async {
    final tasks = await fetchTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final old = tasks[index];
    tasks[index] = Task(
      id: old.id,
      title: old.title,
      description: old.description,
      completed: completed,
      priority: old.priority,
      dueDate: old.dueDate,
      createdAt: old.createdAt,
      priorityOrder: old.priorityOrder,
    );
    await _saveTasks(tasks);
  }

  Future<void> deleteTask(String taskId) async {
    final tasks = await fetchTasks();
    tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks(tasks);
  }

  Future<void> updateTask({
    required String taskId,
    required String title,
    required String description,
    required String priority,
    DateTime? dueDate,
  }) async {
    final tasks = await fetchTasks();
    final index = tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final old = tasks[index];
    tasks[index] = Task(
      id: old.id,
      title: title.trim(),
      description: description.trim(),
      completed: old.completed,
      priority: priority,
      dueDate: dueDate,
      createdAt: old.createdAt,
      priorityOrder: Task.priorityOrderFor(priority),
    );
    await _saveTasks(tasks);
  }

  /// Returns all local tasks and clears the local store.
  ///
  /// Used during sign-in sync: the caller uploads these to Supabase
  /// and then the local cache is emptied.
  Future<List<Task>> drainTasks() async {
    final tasks = await fetchTasks();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    return tasks;
  }

  Future<bool> hasLocalTasks() async {
    final tasks = await fetchTasks();
    return tasks.isNotEmpty;
  }

  // ---------- helpers ----------

  static String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now * 9301 + 49297) % 233280;
    return 'local_$now${rand.toString().padLeft(6, '0')}';
  }

  static Map<String, dynamic> _taskToMap(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'completed': task.completed,
      'priority': task.priority,
      'due_date': task.dueDate?.toIso8601String().split('T').first,
      'created_at': task.createdAt?.toIso8601String(),
      'priority_order': task.priorityOrder,
    };
  }
}