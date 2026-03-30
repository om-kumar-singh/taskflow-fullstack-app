import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/task_draft_service.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final Task? initialTask;

  const TaskFormScreen({
    super.key,
    this.initialTask,
  });

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late final TaskDraftService _draftService;

  DateTime _dueDate = DateTime.now();
  TaskStatus _status = TaskStatus.ToDo;
  String? _blockedByTaskId;

  bool _draftLoaded = false;
  bool _savedSuccessfully = false;

  @override
  void initState() {
    super.initState();

    _draftService = TaskDraftService();

    _titleController =
        TextEditingController(text: widget.initialTask?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialTask?.description ?? '');

    _dueDate = widget.initialTask?.dueDate ?? DateTime.now();
    _status = widget.initialTask?.status ?? TaskStatus.ToDo;
    _blockedByTaskId = widget.initialTask?.blockedByTaskId;

    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final taskId = widget.initialTask?.id;
    final draft = await _draftService.loadDraft(taskId: taskId);
    if (!mounted) return;

    if (draft == null) {
      setState(() {
        _draftLoaded = true;
      });
      return;
    }

    final title = draft['title'] as String? ?? '';
    final description = draft['description'] as String? ?? '';
    final dueDateMillis = draft['dueDateMillis'] as int?;
    final statusIndex = draft['statusIndex'] as int? ?? 0;
    final blocked = draft['blockedByTaskId'] as String?;

    setState(() {
      _titleController.text = title;
      _descriptionController.text = description;
      _dueDate = dueDateMillis == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(dueDateMillis);
      _status = _draftService.statusFromIndex(statusIndex);
      _blockedByTaskId = blocked;
      _draftLoaded = true;
    });
  }

  @override
  void dispose() {
    if (!_savedSuccessfully) {
      // Best-effort draft persistence on leaving the screen.
      final taskId = widget.initialTask?.id;
      unawaited(
        _draftService.saveDraft(
          taskId: taskId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _dueDate,
          status: _status,
          blockedByTaskId: _blockedByTaskId,
        ),
      );
    }

    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(taskLoadingProvider);
    final tasks = ref.watch(taskProvider);

    // Required for blocked-by dropdown (Step 5 dependency list).
    final currentTaskId = widget.initialTask?.id;
    final availableBlockedTasks = tasks
        .where((t) => currentTaskId == null || t.id != currentTaskId)
        .toList(growable: false);

    if (!_draftLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTask == null ? 'Create Task' : 'Edit Task'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return 'Description is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DueDatePickerField(
                  dueDate: _dueDate,
                  onPick: (picked) => setState(() => _dueDate = picked),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TaskStatus>(
                      isExpanded: true,
                      value: _status,
                      items: const [
                        DropdownMenuItem(
                          value: TaskStatus.ToDo,
                          child: Text('ToDo'),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.InProgress,
                          child: Text('InProgress'),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.Done,
                          child: Text('Done'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _status = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      isExpanded: true,
                      value: _blockedByTaskId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...availableBlockedTasks.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(t.title),
                          ),
                        ),
                        if (_blockedByTaskId != null &&
                            !_containsId(availableBlockedTasks, _blockedByTaskId!))
                          DropdownMenuItem<String?>(
                            value: _blockedByTaskId,
                            child: const Text('Unknown task'),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() => _blockedByTaskId = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final nav = Navigator.of(context);

                          final valid =
                              _formKey.currentState?.validate() ?? false;
                          if (!valid) return;

                          final title = _titleController.text.trim();
                          final description = _descriptionController.text.trim();

                          final Task task = widget.initialTask == null
                              ? Task(
                                  title: title,
                                  description: description,
                                  dueDate: _dueDate,
                                  status: _status,
                                  blockedByTaskId: _blockedByTaskId,
                                )
                              : widget.initialTask!.copyWith(
                                  title: title,
                                  description: description,
                                  dueDate: _dueDate,
                                  status: _status,
                                  blockedByTaskId: _blockedByTaskId,
                                );

                          if (widget.initialTask == null) {
                            await ref
                                .read(taskProvider.notifier)
                                .addTask(task);
                            await _draftService.clearDraft(taskId: null);
                          } else {
                            await ref
                                .read(taskProvider.notifier)
                                .updateTask(task);
                            await _draftService.clearDraft(
                              taskId: widget.initialTask!.id,
                            );
                          }

                          if (!mounted) return;
                          _savedSuccessfully = true;
                          nav.pop();
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(widget.initialTask == null ? 'Save' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _containsId(List<Task> tasks, String id) {
    for (final t in tasks) {
      if (t.id == id) return true;
    }
    return false;
  }
}

class _DueDatePickerField extends StatelessWidget {
  final DateTime dueDate;
  final ValueChanged<DateTime> onPick;

  const _DueDatePickerField({
    required this.dueDate,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final dateText =
        MaterialLocalizations.of(context).formatFullDate(dueDate);

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: dueDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked == null) return;
        onPick(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Due Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateText,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }
}

