import 'package:hive/hive.dart';

import '../models/task.dart';

class TaskDraftService {
  static const String _boxName = 'task_drafts';

  String _keyForCreate() => 'create';
  String _keyForEdit(String taskId) => 'edit_$taskId';

  String keyFor({required String? taskId}) {
    if (taskId == null) return _keyForCreate();
    return _keyForEdit(taskId);
  }

  Future<void> saveDraft({
    required String? taskId,
    required String title,
    required String description,
    required DateTime dueDate,
    required TaskStatus status,
    required String? blockedByTaskId,
  }) async {
    final box = await Hive.openBox<dynamic>(_boxName);

    await box.put(
      keyFor(taskId: taskId),
      <String, dynamic>{
        'title': title,
        'description': description,
        'dueDateMillis': dueDate.millisecondsSinceEpoch,
        'statusIndex': _statusToIndex(status),
        'blockedByTaskId': blockedByTaskId,
      },
    );
  }

  Future<Map<String, dynamic>?> loadDraft({required String? taskId}) async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final raw = box.get(keyFor(taskId: taskId));
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    return null;
  }

  Future<void> clearDraft({required String? taskId}) async {
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.delete(keyFor(taskId: taskId));
  }

  int _statusToIndex(TaskStatus status) {
    switch (status) {
      case TaskStatus.ToDo:
        return 0;
      case TaskStatus.InProgress:
        return 1;
      case TaskStatus.Done:
        return 2;
    }
  }

  TaskStatus statusFromIndex(int index) {
    switch (index) {
      case 0:
        return TaskStatus.ToDo;
      case 1:
        return TaskStatus.InProgress;
      case 2:
        return TaskStatus.Done;
      default:
        return TaskStatus.ToDo;
    }
  }
}

