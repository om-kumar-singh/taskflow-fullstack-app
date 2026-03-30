import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import 'status_chip.dart';
import '../utils/ui_constants.dart';

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

  Color _leftBorderColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.ToDo:
        return Colors.grey.shade400;
      case TaskStatus.InProgress:
        return const Color(0xFFFF9933);
      case TaskStatus.Done:
        return const Color(0xFF138808);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardPadding = kSpacing16;

    final dateText = DateFormat.yMMMd().format(task.dueDate);
    final effectiveOpacity = isBlocked ? 0.55 : 1.0;
    final query = highlightQuery.trim();

    final scale = isBlocked ? 0.985 : 1.0;
    final elevation = isBlocked ? 1.0 : 2.5;
    final shadowAlpha = isBlocked ? 0.03 : 0.07;
    final leftBorderColor = _leftBorderColor(task.status);

    return AnimatedOpacity(
      opacity: effectiveOpacity,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.diagonal3Values(scale, scale, 1),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: kCircularBorder16,
          ),
          elevation: elevation,
          shadowColor: Colors.black.withValues(alpha: shadowAlpha),
          child: InkWell(
            borderRadius: kCircularBorder16,
            onTap: isBlocked ? null : onTap,
            child: ClipRRect(
              borderRadius: kCircularBorder16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: kCircularBorder16,
                  border: Border(
                    left: BorderSide(color: leftBorderColor, width: 5),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle(context, task.title, query),
                      const SizedBox(height: kSpacing8),
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: kSpacing8),
                      Row(
                        children: [
                          StatusChip(status: task.status),
                        ],
                      ),
                      if (isBlocked) ...[
                        const SizedBox(height: kSpacing8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline, size: 18),
                            const SizedBox(width: kSpacing8),
                            Expanded(
                              child: Text(
                                'Blocked by: ${blockedByTitle ?? 'Unknown'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.black.withValues(alpha: 0.65),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, String title, String query) {
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ) ??
        const TextStyle(fontWeight: FontWeight.w800, fontSize: 16);

    if (query.isEmpty) {
      return Text(
        title,
        style: baseStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
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
            backgroundColor: const Color(0xFF000080).withValues(alpha: 0.18),
          ),
        ),
      );

      start = matchIndex + query.length;
      if (start >= title.length) break;
    }

    return Text.rich(
      TextSpan(children: spans, style: baseStyle),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

