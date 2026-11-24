import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_service.dart';
import '../widgets/task_form_page.dart';

class EditTaskPage extends StatelessWidget {
  final Task task;

  const EditTaskPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return TaskFormPage(
      appBarTitle: 'Edit Task',
      heading: 'Edit your task',
      subtitle: 'Update your task details below.',
      submitLabel: 'Save Changes',
      submitIcon: Icons.save_outlined,
      errorPrefix: 'Could not update task',
      initial: TaskDraft(
        title: task.title,
        description: task.description,
        priority: task.priority,
        dueDate: task.dueDate,
      ),
      onSubmit: (draft) async {
        await TaskService().updateTask(
          taskId: task.id,
          title: draft.title,
          description: draft.description,
          priority: draft.priority,
          dueDate: draft.dueDate,
        );
        return Task(
          id: task.id,
          title: draft.title,
          description: draft.description,
          completed: task.completed,
          priority: draft.priority,
          dueDate: draft.dueDate,
          createdAt: task.createdAt,
          priorityOrder: Task.priorityOrderFor(draft.priority),
        );
      },
    );
  }
}