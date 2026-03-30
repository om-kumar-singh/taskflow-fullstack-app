import 'package:flutter/material.dart';

import '../models/task.dart';

class StatusChip extends StatelessWidget {
  final TaskStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  Color _bg(TaskStatus s) {
    switch (s) {
      case TaskStatus.ToDo:
        return Colors.grey.shade300;
      case TaskStatus.InProgress:
        return const Color(0xFFFFE3C2); // light saffron
      case TaskStatus.Done:
        return const Color(0xFFCFF5D5); // light green
    }
  }

  Color _fg(TaskStatus s) {
    switch (s) {
      case TaskStatus.ToDo:
        return Colors.grey.shade800;
      case TaskStatus.InProgress:
        return const Color(0xFF8A4B00); // deep saffron-brown
      case TaskStatus.Done:
        return const Color(0xFF1E6B2D); // deep green
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bg(status);
    final fg = _fg(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

