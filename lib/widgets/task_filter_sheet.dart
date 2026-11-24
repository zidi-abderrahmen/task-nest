import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/task_filters.dart';

class TaskFilterResult {
  const TaskFilterResult(this.status, this.priority);
  final TaskStatusFilter status;
  final TaskPriorityFilter priority;
}

class TaskFilterSheet extends StatefulWidget {
  const TaskFilterSheet({
    super.key,
    required this.initialStatus,
    required this.initialPriority,
  });

  final TaskStatusFilter initialStatus;
  final TaskPriorityFilter initialPriority;

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskStatusFilter _status = widget.initialStatus;
  late TaskPriorityFilter _priority = widget.initialPriority;

  @override
  Widget build(BuildContext context) {
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SectionLabel('Status'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskStatusFilter.values
                .map((s) => _Chip(
                      label: s.label,
                      selected: _status == s,
                      onTap: () => setState(() => _status = s),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Priority'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskPriorityFilter.values
                .map((p) => _Chip(
                      label: p.label,
                      selected: _priority == p,
                      onTap: () => setState(() => _priority = p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() {
                  _status = TaskStatusFilter.all;
                  _priority = TaskPriorityFilter.all;
                }),
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pop(TaskFilterResult(_status, _priority)),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
      onSelected: (v) {
        if (v) onTap();
      },
    );
  }
}