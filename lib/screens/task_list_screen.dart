import 'dart:async';

// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';
import '../utils/ui_constants.dart';

enum TaskStatusFilter {
  all,
  todo,
  inProgress,
  done,
}

final taskSearchQueryProvider = StateProvider<String>((ref) => '');
final taskDebouncedSearchQueryProvider = StateProvider<String>((ref) => '');
final taskSelectedFilterProvider = StateProvider<TaskStatusFilter>(
  (ref) => TaskStatusFilter.all,
);

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(taskProvider);
    final isLoading = ref.watch(taskLoadingProvider);
    final selectedFilter = ref.watch(taskSelectedFilterProvider);
    final debouncedQuery = ref.watch(taskDebouncedSearchQueryProvider);
    final tasksById = {for (final t in tasks) t.id: t};

    final normalizedQuery = debouncedQuery.trim().toLowerCase();

    bool matchesFilter(Task t) {
      switch (selectedFilter) {
        case TaskStatusFilter.all:
          return true;
        case TaskStatusFilter.todo:
          return t.status == TaskStatus.ToDo;
        case TaskStatusFilter.inProgress:
          return t.status == TaskStatus.InProgress;
        case TaskStatusFilter.done:
          return t.status == TaskStatus.Done;
      }
    }

    bool matchesSearch(Task t) {
      if (normalizedQuery.isEmpty) return true;
      return t.title.toLowerCase().contains(normalizedQuery);
    }

    final filteredTasks = tasks.where((t) {
      return matchesFilter(t) && matchesSearch(t);
    }).toList(growable: false);

    final isTasksEmpty = tasks.isEmpty;
    final isFilteredEmpty = !isTasksEmpty && filteredTasks.isEmpty;
    final hasSearchText = normalizedQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        foregroundColor: const Color(0xFF000080),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF9933),
                Colors.white,
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kSpacing16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks by title',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: kCircularBorder12,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: kCircularBorder12,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: kCircularBorder12,
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) {
                  ref.read(taskSearchQueryProvider.notifier).state = value;
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                    ref
                        .read(taskDebouncedSearchQueryProvider.notifier)
                        .state = value;
                  });
                },
              ),
              const SizedBox(height: kSpacing16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
                  borderRadius: kCircularBorder12,
                ),
                padding: const EdgeInsets.symmetric(horizontal: kSpacing8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TaskStatusFilter>(
                    isExpanded: true,
                    value: selectedFilter,
                    items: const [
                      DropdownMenuItem(
                        value: TaskStatusFilter.all,
                        child: Text('All'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatusFilter.todo,
                        child: Text('ToDo'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatusFilter.inProgress,
                        child: Text('InProgress'),
                      ),
                      DropdownMenuItem(
                        value: TaskStatusFilter.done,
                        child: Text('Done'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(taskSelectedFilterProvider.notifier).state = value;
                    },
                  ),
                ),
              ),
              const SizedBox(height: kSpacing16),
              if (isLoading)
                const LinearProgressIndicator(
                  minHeight: 2,
                ),
              if (isLoading) const SizedBox(height: kSpacing8),
              Expanded(
                child: isTasksEmpty
                    ? const Center(
                        child: Text('No tasks yet. Create your first task!'),
                      )
                    : isFilteredEmpty
                        ? Center(
                            child: Text(
                              hasSearchText
                                  ? 'No tasks match your search'
                                  : 'No tasks found.',
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredTasks.length,
                            itemBuilder: (context, index) {
                              final task = filteredTasks[index];
                              final blockedByTaskId = task.blockedByTaskId;

                              final blockedByTask =
                                  blockedByTaskId == null
                                      ? null
                                      : tasksById[blockedByTaskId];

                              final isBlocked = blockedByTask != null &&
                                  blockedByTask.status != TaskStatus.Done;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: kSpacing8),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, animation) =>
                                      FadeTransition(opacity: animation, child: child),
                                  child: TaskCard(
                                    key: ValueKey(
                                      '${task.id}_${selectedFilter.name}_${debouncedQuery.trim()}',
                                    ),
                                    task: task,
                                    isBlocked: isBlocked,
                                    blockedByTitle: blockedByTask?.title,
                                    highlightQuery: debouncedQuery,
                                    onTap: () {
                                      // Edit screen is implemented in Step 6.
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TaskFormScreen(
                                            initialTask: task,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

