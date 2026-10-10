import 'package:flutter/material.dart';
import '../models/task.dart';
import 'edit_task_page.dart';

class TaskDetailsPage extends StatefulWidget {
  final Task task;

  const TaskDetailsPage({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late Task _task;

  static const _primary = Color(0xFF4F46E5);
  static const _background = Color(0xFFF8FAFC);
  static const _secondaryText = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _task = widget.task;
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

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _secondaryText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editTask() async {
    final updatedTask = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (_) => EditTaskPage(task: _task),
      ),
    );

    if (!mounted) return;

    if (updatedTask != null) {
      setState(() {
        _task = updatedTask;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(_task.priority);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _task.title.isEmpty
                        ? 'Untitled task'
                        : _task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  _detailRow(
                    icon: Icons.description_outlined,
                    label: 'Description',
                    value: _task.description.isEmpty
                        ? 'No description'
                        : _task.description,
                  ),
                  const Divider(),
                  _detailRow(
                    icon: _task.completed
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    label: 'Status',
                    value: _task.completed ? 'Completed' : 'Pending',
                  ),
                  const Divider(),
                  _detailRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    value: _task.priority,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  _detailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Due Date',
                    value: _formatDate(_task.dueDate),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _editTask,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}