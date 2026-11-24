import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../theme/app_theme.dart';
import 'edit_task_page.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  const TaskDetailsPage({super.key, required this.task});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  // ---------- helpers ----------

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Color _priorityColor(String priority) => switch (priority) {
        'High' => AppColors.danger,
        'Medium' => AppColors.warning,
        _ => AppColors.success,
      };

  bool get _isOverdue {
    final due = _task.dueDate;
    if (_task.completed || due == null) return false;
    return DateUtils.dateOnly(due)
        .isBefore(DateUtils.dateOnly(DateTime.now()));
  }

  String? get _relativeDueLabel {
    final due = _task.dueDate;
    if (due == null || _task.completed) return null;

    final today = DateUtils.dateOnly(DateTime.now());
    final diff = DateUtils.dateOnly(due).difference(today).inDays;

    if (diff < 0) {
      final n = -diff;
      return '$n ${n == 1 ? 'day' : 'days'} overdue';
    }
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in $diff days';
  }

  // ---------- actions ----------

  Future<void> _editTask() async {
    final updated = await Navigator.of(context).push<Task>(
      MaterialPageRoute(builder: (_) => EditTaskPage(task: _task)),
    );
    if (!mounted || updated == null) return;
    setState(() => _task = updated);
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Are you sure you want to delete "${_task.title}"?'),
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
      await TaskService().deleteTask(_task.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete task: $e')),
      );
    }
  }

  Future<void> _copyDescription() async {
    await Clipboard.setData(ClipboardData(text: _task.description));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Description copied')));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            tooltip: 'Delete task',
            onPressed: _deleteTask,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeroCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildDescriptionCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildDetailsCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final completed = _task.completed;
    final overdue = _isOverdue;

    final borderColor = completed
        ? AppColors.success.withValues(alpha: 0.35)
        : overdue
            ? AppColors.danger.withValues(alpha: 0.35)
            : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusPill(completed: completed, overdue: overdue),
              _PriorityPill(
                priority: _task.priority,
                color: _priorityColor(_task.priority),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _task.title.isEmpty ? 'Untitled task' : _task.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.textPrimary,
              decoration: completed
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          if (_relativeDueLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  overdue ? Icons.warning_amber_rounded : Icons.schedule,
                  size: 16,
                  color: overdue ? AppColors.danger : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _relativeDueLabel!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: overdue
                        ? AppColors.danger
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    final empty = _task.description.isEmpty;

    return _InfoCard(
      title: 'DESCRIPTION',
      trailing: empty
          ? null
          : IconButton(
              tooltip: 'Copy description',
              visualDensity: VisualDensity.compact,
              onPressed: _copyDescription,
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
      child: Text(
        empty ? 'No description provided.' : _task.description,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: empty ? AppColors.textSecondary : AppColors.textPrimary,
          fontStyle: empty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final priorityColor = _priorityColor(_task.priority);

    return _InfoCard(
      title: 'DETAILS',
      child: Column(
        children: [
          _DetailRow(
            icon: _task.completed
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            iconColor: _task.completed
                ? AppColors.success
                : AppColors.textSecondary,
            label: 'Status',
            value: _task.completed ? 'Completed' : 'Pending',
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.flag_outlined,
            iconColor: priorityColor,
            label: 'Priority',
            value: _task.priority,
            trailing: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            iconColor: _isOverdue ? AppColors.danger : AppColors.primary,
            label: 'Due date',
            value: _formatDate(_task.dueDate),
            valueColor: _isOverdue ? AppColors.danger : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _editTask,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- small reusable widgets ----------

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.completed, required this.overdue});

  final bool completed;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final IconData icon;
    late final String label;

    if (completed) {
      color = AppColors.success;
      icon = Icons.check_circle;
      label = 'Completed';
    } else if (overdue) {
      color = AppColors.danger;
      icon = Icons.warning_amber_rounded;
      label = 'Overdue';
    } else {
      color = AppColors.textSecondary;
      icon = Icons.schedule;
      label = 'Pending';
    }

    return _Pill(color: color, icon: icon, label: label);
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({required this.priority, required this.color});

  final String priority;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Pill(color: color, icon: Icons.flag_outlined, label: priority);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}