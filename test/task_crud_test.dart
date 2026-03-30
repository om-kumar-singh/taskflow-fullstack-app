import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:task_manager_app/models/task.dart';
import 'package:task_manager_app/providers/task_provider.dart';
import 'package:task_manager_app/services/task_service.dart';
import 'package:task_manager_app/services/task_draft_service.dart';

Directory? _tempDir;

Future<void> _setupHive() async {
  _tempDir = await Directory.systemTemp.createTemp('task_manager_hive_test_');
  Hive.init(_tempDir!.path);

  Hive.registerAdapter(TaskStatusAdapter());
  Hive.registerAdapter(TaskAdapter());

  await Hive.openBox<Task>('tasks');
}

Future<void> _tearDownHive() async {
  if (Hive.isBoxOpen('tasks')) {
    await Hive.box<Task>('tasks').close();
  }
  if (Hive.isBoxOpen('tasks')) {
    await Hive.deleteBoxFromDisk('tasks');
  }
  await Hive.close();
  await _tempDir?.delete(recursive: true);
}

Task _task({
  required String title,
  required TaskStatus status,
  String? id,
  String description = 'desc',
  DateTime? dueDate,
  String? blockedByTaskId,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate ?? DateTime(2026, 1, 1),
    status: status,
    blockedByTaskId: blockedByTaskId,
  );
}

bool isBlockedByLogic(Task task, Task? dependency) {
  return dependency != null && dependency.status != TaskStatus.Done;
}

void main() {
  group('Task CRUD + Hive persistence', () {
    setUpAll(() async {
      // Ensure adapters are registered once before tests.
      // ignore: unnecessary_statements
      await _setupHive();
    });

    tearDownAll(() async {
      await _tearDownHive();
    });

    test('Create -> stored in Hive -> Read back after reopen', () async {
      final service = const TaskService();

      await service.addTask(
        _task(title: 'Task A', status: TaskStatus.ToDo, id: 'uuid-a'),
      );

      final tasksBefore = service.getAllTasks();
      expect(tasksBefore.length, 1);
      expect(tasksBefore.first.id, 'uuid-a');
      expect(tasksBefore.first.title, 'Task A');

      await Hive.box<Task>('tasks').close();
      await Hive.openBox<Task>('tasks');

      final tasksAfter = service.getAllTasks();
      expect(tasksAfter.length, 1);
      expect(tasksAfter.first.id, 'uuid-a');
      expect(tasksAfter.first.title, 'Task A');
    });

    test('Task constructor generates UUID when id omitted', () {
      final t = _task(
        title: 'UUID Task',
        status: TaskStatus.ToDo,
        id: null,
        dueDate: DateTime(2026, 1, 1),
      );
      expect(t.id, isNotEmpty);
    });

    test('Update persists changes in Hive', () async {
      final service = const TaskService();

      final original = _task(title: 'Task B', status: TaskStatus.ToDo, id: 'uuid-b');
      await service.addTask(original);

      final updated = original.copyWith(status: TaskStatus.InProgress);
      await service.updateTask(updated);

      final tasks = service.getAllTasks();
      final fetched = tasks.where((t) => t.id == 'uuid-b').single;
      expect(fetched.status, TaskStatus.InProgress);
    });

    test('Delete removes task from Hive', () async {
      final service = const TaskService();

      final t = _task(title: 'Task C', status: TaskStatus.ToDo, id: 'uuid-c');
      await service.addTask(t);

      await service.deleteTask('uuid-c');
      final tasks = service.getAllTasks();
      expect(tasks.any((x) => x.id == 'uuid-c'), isFalse);
    });

    test('Blocked-by logic: becomes active after dependency Done', () async {
      final service = const TaskService();

      final dep = _task(title: 'Dependency', status: TaskStatus.ToDo, id: 'uuid-dep');
      final blocked = _task(
        title: 'Blocked',
        status: TaskStatus.ToDo,
        id: 'uuid-blocked',
        blockedByTaskId: 'uuid-dep',
      );

      await service.addTask(dep);
      await service.addTask(blocked);

      final depTask = service.getAllTasks().where((t) => t.id == 'uuid-dep').single;
      final blockedTask = service.getAllTasks().where((t) => t.id == 'uuid-blocked').single;

      expect(isBlockedByLogic(blockedTask, depTask), isTrue);

      await service.updateTask(depTask.copyWith(status: TaskStatus.Done));

      final depUpdated = service.getAllTasks().where((t) => t.id == 'uuid-dep').single;
      expect(isBlockedByLogic(blockedTask.copyWith(), depUpdated), isFalse);
    });

    test('Notifier loads existing tasks on initialization', () async {
      final service = const TaskService();

      // Clear current tasks.
      final box = Hive.box<Task>('tasks');
      for (final key in box.keys.toList(growable: false)) {
        await box.delete(key);
      }

      final t = _task(title: 'Init Task', status: TaskStatus.ToDo, id: 'uuid-init');
      await service.addTask(t);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskProvider.notifier);
      await notifier.loadTasks();

      final tasks = container.read(taskProvider);
      expect(tasks.length, 1);
      expect(tasks.single.id, 'uuid-init');
    });

    test('Deleting dependency removes blocked state (no orphan crash)', () async {
      final service = const TaskService();

      final dep = _task(
        title: 'Dependency',
        status: TaskStatus.ToDo,
        id: 'uuid-dep2',
      );
      final blocked = _task(
        title: 'Blocked',
        status: TaskStatus.ToDo,
        id: 'uuid-blocked2',
        blockedByTaskId: 'uuid-dep2',
      );

      await service.addTask(dep);
      await service.addTask(blocked);

      // Now delete dependency task A.
      await service.deleteTask('uuid-dep2');

      final remaining = service.getAllTasks();
      final blockedTask = remaining.where((t) => t.id == 'uuid-blocked2').single;
      final depMatches = remaining.where((t) => t.id == 'uuid-dep2');
      final Task? missingDependency = depMatches.isEmpty ? null : depMatches.single;

      expect(isBlockedByLogic(blockedTask, missingDependency), isFalse);
    });

    test('Notifier prevents duplicate submissions', () async {
      // Clear tasks box by replacing it with a fresh one.
      final box = Hive.box<Task>('tasks');
      // Best-effort clear; use keys to avoid concurrent modification.
      for (final key in box.keys.toList(growable: false)) {
        await box.delete(key);
      }

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskProvider.notifier);

      final t1 = _task(title: 'Dup 1', status: TaskStatus.ToDo, id: 'uuid-1');
      final t2 = _task(title: 'Dup 2', status: TaskStatus.ToDo, id: 'uuid-2');

      final f1 = notifier.addTask(t1);
      final f2 = notifier.addTask(t2);

      await Future.wait([f1, f2]);

      final tasks = container.read(taskProvider);
      // Because duplicate click is blocked during saving, only the first add should win.
      expect(tasks.length, 1);
      expect(tasks.single.id, 'uuid-1');
    });

    test('Draft persistence: save -> load -> clear', () async {
      final drafts = TaskDraftService();

      await drafts.saveDraft(
        taskId: null,
        title: 'Draft title',
        description: 'Draft description',
        dueDate: DateTime(2026, 2, 1),
        status: TaskStatus.InProgress,
        blockedByTaskId: 'some-task',
      );

      final loaded = await drafts.loadDraft(taskId: null);
      expect(loaded, isNotNull);
      expect(loaded?['title'], 'Draft title');
      expect(loaded?['description'], 'Draft description');

      await drafts.clearDraft(taskId: null);
      final afterClear = await drafts.loadDraft(taskId: null);
      expect(afterClear, isNull);
    });

    test('Notifier updateTask updates blocked logic', () async {
      final service = const TaskService();
      final box = Hive.box<Task>('tasks');

      // Clear tasks box.
      for (final key in box.keys.toList(growable: false)) {
        await box.delete(key);
      }

      final dep = _task(title: 'Dep', status: TaskStatus.ToDo, id: 'uuid-dep3');
      final blocked = _task(
        title: 'Blocked',
        status: TaskStatus.ToDo,
        id: 'uuid-blocked3',
        blockedByTaskId: 'uuid-dep3',
      );

      await service.addTask(dep);
      await service.addTask(blocked);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskProvider.notifier);
      await notifier.loadTasks();

      Map<String, Task> byId(List<Task> ts) => {for (final t in ts) t.id: t};

      List<Task> state1 = container.read(taskProvider);
      final tasksById1 = byId(state1);
      final depTask1 = tasksById1['uuid-dep3']!;
      final blockedTask1 = tasksById1['uuid-blocked3']!;
      final depForBlocked1 = tasksById1[blockedTask1.blockedByTaskId];
      expect(isBlockedByLogic(blockedTask1, depForBlocked1), isTrue);

      await notifier.updateTask(depTask1.copyWith(status: TaskStatus.Done));

      final state2 = container.read(taskProvider);
      final tasksById2 = byId(state2);
      final depTask2 = tasksById2['uuid-dep3']!;
      final blockedTask2 = tasksById2['uuid-blocked3']!;
      final depForBlocked2 = tasksById2[blockedTask2.blockedByTaskId];
      expect(depTask2.status, TaskStatus.Done);
      expect(isBlockedByLogic(blockedTask2, depForBlocked2), isFalse);
    });

    test('Notifier deleteTask removes task from provider state', () async {
      final box = Hive.box<Task>('tasks');
      for (final key in box.keys.toList(growable: false)) {
        await box.delete(key);
      }

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(taskProvider.notifier);

      // Add via notifier (exercises delay + refresh)
      final t = _task(title: 'ToDelete', status: TaskStatus.ToDo, id: 'uuid-del3');
      await notifier.addTask(t);

      final stateAfterAdd = container.read(taskProvider);
      expect(stateAfterAdd.any((x) => x.id == 'uuid-del3'), isTrue);

      await notifier.deleteTask('uuid-del3');

      final stateAfterDelete = container.read(taskProvider);
      expect(stateAfterDelete.any((x) => x.id == 'uuid-del3'), isFalse);
    });
  });
}

