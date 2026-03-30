import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final String? blockedByTitle;
  final VoidCallback? onTap;
  final String highlightQuery;

  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    required this.blockedByTitle,
    required this.onTap,
    this.highlightQuery = '',
  });

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.ToDo:
        return Colors.grey;
      case TaskStatus.InProgress:
        return Colors.blue;
      case TaskStatus.Done:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardRadius = 12.0;
    const cardPadding = 16.0;

    final dateText = DateFormat.yMMMd().format(task.dueDate);

    final badgeColor = _statusColor(task.status);
    final effectiveOpacity = isBlocked ? 0.5 : 1.0;
    final query = highlightQuery.trim();

    return Opacity(
      opacity: effectiveOpacity,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(cardRadius),
          onTap: isBlocked ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(context, task.title, query),
                const SizedBox(height: 8),
                Text(
                  dateText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        task.status.name,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (isBlocked) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Blocked by: ${blockedByTitle ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title, String query) {
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle(fontWeight: FontWeight.w700);

    if (query.isEmpty) {
      return Text(title, style: baseStyle);
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final matchIndex = lowerTitle.indexOf(lowerQuery, start);
      if (matchIndex == -1) {
        spans.add(TextSpan(text: title.substring(start), style: baseStyle));
        break;
      }

      if (matchIndex > start) {
        spans.add(
          TextSpan(
            text: title.substring(start, matchIndex),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: title.substring(matchIndex, matchIndex + query.length),
          style: baseStyle.copyWith(
            backgroundColor: Colors.yellow.withValues(alpha: 0.35),
          ),
        ),
      );

      start = matchIndex + query.length;
      if (start >= title.length) break;
    }

    return RichText(text: TextSpan(children: spans, style: baseStyle));
  }
}

