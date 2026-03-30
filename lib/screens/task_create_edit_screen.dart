import 'package:flutter/material.dart';

import '../models/task.dart';

/// Placeholder screen for create/edit.
///
/// This will be replaced with the full form UI in Step 6.
class TaskCreateEditScreen extends StatelessWidget {
  final Task? initialTask;

  const TaskCreateEditScreen({
    super.key,
    this.initialTask,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialTask == null ? 'Create Task' : 'Edit Task'),
      ),
      body: const Center(
        child: Text('Create/Edit form will be implemented in Step 6.'),
      ),
    );
  }
}

