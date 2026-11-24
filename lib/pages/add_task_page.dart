import 'package:flutter/material.dart';

import '../services/task_service.dart';
import '../widgets/task_form_page.dart';

class AddTaskPage extends StatelessWidget {
  const AddTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TaskFormPage(
      appBarTitle: 'Add Task',
      heading: 'Create a new task',
      subtitle: 'Organize your next activity.',
      submitLabel: 'Add Task',
      submitIcon: Icons.add,
      errorPrefix: 'Could not add task',
      initial: const TaskDraft(
        title: '',
        description: '',
        priority: 'Medium',
        dueDate: null,
      ),
      onSubmit: (draft) async {
        await TaskService().addTask(
          title: draft.title,
          description: draft.description,
          priority: draft.priority,
          dueDate: draft.dueDate,
        );
        return true; // HomePage checks `== true`
      },
    );
  }
}