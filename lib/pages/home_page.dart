import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import '../utils/task_filters.dart';
import '../widgets/state_widgets.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_sheet.dart';
import '../widgets/task_list_header.dart';
import 'add_task_page.dart';
import 'task_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _taskService = TaskService();

  List<Task>? _tasks;
  Object? _error;
  bool _loading = true;

  TaskStatusFilter _statusFilter = TaskStatusFilter.all;
  TaskPriorityFilter _priorityFilter = TaskPriorityFilter.all;

  bool get _hasFilters =>
      _statusFilter != TaskStatusFilter.all ||
      _priorityFilter != TaskPriorityFilter.all;

  bool get _hasSearch => _searchController.text.trim().isNotEmpty;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- data ----------

  Future<void> _loadTasks({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final tasks = await _taskService.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _loadTasks(showLoader: false);

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- actions ----------

  Future<void> _toggleTask(Task task) async {
    HapticFeedback.lightImpact();
    try {
      await _taskService.updateTaskCompletion(
        taskId: task.id,
        completed: !task.completed,
      );
      if (!mounted) return;
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not update task: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _taskService.deleteTask(task.id);
      if (!mounted) return;
      await _refresh();
      _showSnack('Task deleted successfully.');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not delete task: $e');
    }
  }

  Future<void> _openAddTask() async {
    final added = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AddTaskPage()));
    if (!mounted || added != true) return;
    await _refresh();
  }

  Future<void> _openTaskDetails(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)),
    );
    if (!mounted) return;
    await _refresh();
  }

  Future<void> _showFilterSheet() async {
    final result = await showModalBottomSheet<TaskFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
      ),
      builder: (_) => TaskFilterSheet(
        initialStatus: _statusFilter,
        initialPriority: _priorityFilter,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _statusFilter = result.status;
      _priorityFilter = result.priority;
    });
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('TaskNest'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTask,
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_greeting 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stay organized today.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSearchRow(),
                  if (_hasFilters) ...[
                    const SizedBox(height: 12),
                    _buildActiveFilterChips(),
                  ],
                  const SizedBox(height: 16),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _hasFilters ? AppColors.primary : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: _hasFilters ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: _showFilterSheet,
            child: Tooltip(
              message: 'Filter tasks',
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(
                  Icons.tune,
                  color: _hasFilters ? Colors.white : AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilterChips() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        if (_statusFilter != TaskStatusFilter.all)
          InputChip(
            label: Text(_statusFilter.label),
            onDeleted: () =>
                setState(() => _statusFilter = TaskStatusFilter.all),
          ),
        if (_priorityFilter != TaskPriorityFilter.all)
          InputChip(
            label: Text(_priorityFilter.label),
            onDeleted: () =>
                setState(() => _priorityFilter = TaskPriorityFilter.all),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _tasks == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          TaskCardSkeleton(),
          TaskCardSkeleton(),
          TaskCardSkeleton(),
          TaskCardSkeleton(),
        ],
      );
    }

    if (_error != null && _tasks == null) {
      return ErrorState(onRetry: () => _loadTasks());
    }

    final all = _tasks ?? const <Task>[];
    final filtered = filterTasks(
      all,
      query: _searchController.text,
      status: _statusFilter,
      priority: _priorityFilter,
    );

    final completed = filtered.where((t) => t.completed).length;
    final pending = filtered.length - completed;
    final isTrulyEmpty = all.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          if (filtered.isNotEmpty) ...[
            TaskListHeader(
              total: filtered.length,
              completed: completed,
              pending: pending,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Tasks (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_hasFilters)
                TextButton(
                  onPressed: () => setState(() {
                    _statusFilter = TaskStatusFilter.all;
                    _priorityFilter = TaskPriorityFilter.all;
                  }),
                  child: const Text('Clear filters'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _buildEmptyState(isTrulyEmpty: isTrulyEmpty)
          else
            ...filtered.map(
              (task) => TaskCard(
                key: ValueKey(task.id),
                task: task,
                onToggle: () => _toggleTask(task),
                onOpenDetails: () => _openTaskDetails(task),
                onDelete: () => _deleteTask(task),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required bool isTrulyEmpty}) {
    if (isTrulyEmpty) {
      return EmptyState(
        icon: Icons.task_alt,
        title: 'No tasks yet',
        message: 'Add your first task to get started.',
        action: FilledButton.icon(
          onPressed: _openAddTask,
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
        ),
      );
    }

    return EmptyState(
      icon: Icons.search_off,
      title: 'No matching tasks',
      message: _hasSearch
          ? 'Try a different search term or adjust your filters.'
          : 'Adjust your filters to see more tasks.',
      action: TextButton.icon(
        onPressed: () {
          _searchController.clear();
          setState(() {
            _statusFilter = TaskStatusFilter.all;
            _priorityFilter = TaskPriorityFilter.all;
          });
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Reset'),
      ),
    );
  }
}