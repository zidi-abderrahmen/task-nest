import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../utils/task_filters.dart';
import 'add_task_page.dart';
import 'task_details_page.dart';
import 'statistics_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();

  late Future<List<Task>> _tasksFuture;

  String _statusFilter = 'All';
  String _priorityFilter = 'All';

  static const _primary = Color(0xFF4F46E5);
  static const _background = Color(0xFFF8FAFC);
  static const _secondaryText = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskService().fetchTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF10B981);
    }
  }

  Future<void> _toggleTask(Task task) async {
    try {
      await TaskService().updateTaskCompletion(
        taskId: task.id,
        completed: !task.completed,
      );

      if (!mounted) return;

      setState(() {
        _tasksFuture = TaskService().fetchTasks();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update task: $error')));
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await TaskService().deleteTask(task.id);

      if (!mounted) return;

      setState(() {
        _tasksFuture = TaskService().fetchTasks();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete task: $error')));
    }
  }

  Future<void> _openAddTask() async {
    final added = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const AddTaskPage()));

    if (!mounted || added != true) return;

    setState(() {
      _tasksFuture = TaskService().fetchTasks();
    });
  }

  Future<void> _openTaskDetails(Task task) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TaskDetailsPage(task: task)));

    if (!mounted) return;

    setState(() {
      _tasksFuture = TaskService().fetchTasks();
    });
  }

  Widget _buildTaskBadge({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet() async {
    var selectedStatus = _statusFilter;
    var selectedPriority = _priorityFilter;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter Tasks',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Pending', 'Completed'].map((status) {
                      final selected = selectedStatus == status;

                      return ChoiceChip(
                        label: Text(status),
                        selected: selected,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        onSelected: (value) {
                          if (!value) return;

                          setSheetState(() {
                            selectedStatus = status;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'High', 'Medium', 'Low'].map((priority) {
                      final selected = selectedPriority == priority;

                      return ChoiceChip(
                        label: Text(priority),
                        selected: selected,
                        selectedColor: const Color(0xFF4F46E5),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                        onSelected: (value) {
                          if (!value) return;

                          setSheetState(() {
                            selectedPriority = priority;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selectedStatus = 'All';
                            selectedPriority = 'All';
                          });
                        },
                        child: const Text('Reset'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _statusFilter = selectedStatus;
                            _priorityFilter = selectedPriority;
                          });

                          Navigator.of(sheetContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Apply Filters'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    final priorityColor = _priorityColor(task.priority);

    final statusColor = task.completed
        ? const Color(0xFF10B981)
        : const Color(0xFF64748B);

    final dueDate = task.dueDate;

    final today = DateUtils.dateOnly(DateTime.now());

    final isOverdue =
        !task.completed &&
        dueDate != null &&
        DateUtils.dateOnly(dueDate).isBefore(today);

    final borderColor = task.completed
        ? const Color(0xFF10B981).withValues(alpha: 0.35)
        : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: () => _toggleTask(task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              task.completed ? Icons.check_circle : Icons.circle_outlined,
              color: statusColor,
              size: 25,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title.isEmpty ? 'Untitled task' : task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),

                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildTaskBadge(
                        label: task.completed ? 'Completed' : 'Pending',
                        color: statusColor,
                        icon: task.completed ? Icons.check : Icons.schedule,
                      ),

                      _buildTaskBadge(
                        label: task.priority,
                        color: priorityColor,
                        icon: Icons.flag_outlined,
                      ),

                      if (dueDate != null)
                        _buildTaskBadge(
                          label: isOverdue
                              ? 'Overdue · ${_formatDate(dueDate)}'
                              : _formatDate(dueDate),
                          color: isOverdue
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                          icon: isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.calendar_today_outlined,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 4),

            SizedBox(
              width: 36,
              child: IconButton(
                tooltip: 'View details',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => _openTaskDetails(task),
                icon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4F46E5),
                  size: 21,
                ),
              ),
            ),

            SizedBox(
              width: 36,
              child: IconButton(
                tooltip: 'Delete task',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => _deleteTask(task),
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFEF4444),
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Statistics',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatisticsPage()));
            },
          ),
        ],
        title: const Text(
          'TaskNest',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning 👋',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Stay organized today.',
                style: TextStyle(fontSize: 14, color: _secondaryText),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    decoration: BoxDecoration(
                      color:
                          (_statusFilter != 'All' || _priorityFilter != 'All')
                          ? const Color(0xFF4F46E5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: IconButton(
                      tooltip: 'Filter tasks',
                      onPressed: _showFilterSheet,
                      icon: Icon(
                        Icons.tune,
                        color:
                            (_statusFilter != 'All' || _priorityFilter != 'All')
                            ? Colors.white
                            : const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: FutureBuilder<List<Task>>(
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Failed to load tasks.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _tasksFuture = TaskService().fetchTasks();
                                });
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    final tasks = snapshot.data ?? [];

                    final filteredTasks = filterTasks(
                      tasks,
                      query: _searchController.text,
                      status: _statusFilter,
                      priority: _priorityFilter,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Tasks (${filteredTasks.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filteredTasks.isEmpty
                              ? Center(
                                  child: Text(
                                    _searchController.text.trim().isEmpty
                                        ? 'No Task Yet, Add One!'
                                        : 'No tasks match your search.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: _secondaryText,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredTasks.length,
                                  itemBuilder: (context, index) {
                                    return _buildTaskCard(filteredTasks[index]);
                                  },
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _openAddTask,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Task'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F46E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
