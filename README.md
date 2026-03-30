# Task Manager App

> A real-world Flutter task management app with clean architecture, polished UI/UX, and reliable local persistence.

## Demo

https://github.com/user-attachments/assets/ff7237db-ba3f-4d18-8af9-d633bbb1ad92

## Features (implemented)

### Task Management (Hive + Riverpod)

- Task model persisted locally in a Hive `tasks` box.
- Full CRUD via `TaskService` (create, read, update, delete).
- Riverpod `TaskNotifier` manages loading state and prevents duplicate submissions.
- Create/Edit form supports **draft persistence**:
  - Draft auto-saves when you leave the screen.
  - Draft restores when you reopen Create/Edit.
  - Drafts are stored in a separate Hive `task_drafts` box.
- Delete UX:
  - Swipe right on a task card to delete (with confirmation dialog).
  - Snackbar feedback on deletion.

### Search, Filter & Highlight

- Debounced (300ms) search by task title (case-insensitive).
- Status filter: All, ToDo, InProgress, Done.
- Matching title text is highlighted inline using `RichText` / `TextSpan`.

### Blocked Task UX

If a task is blocked by another task that is not `Done`:

- The card is greyed out.
- Interaction is disabled.
- The card shows **Blocked by: \<Task Title\>**.

## UI polish

- Rounded cards with soft shadows and clear visual hierarchy (title → date → status).
- Subtle list animations and lightweight card transitions.
- Loading indicators on the task list and Save/Update button.
- Friendly empty states:
  - `No tasks yet. Create your first task!`
  - `No tasks match your search`

## Tech Stack

- Flutter
- Material 3
- Riverpod (StateNotifier)
- Hive (local persistence)
- intl (date formatting)
- uuid (Task id generation)

## Quality & Validation

- `flutter analyze` passes with no issues.
- Automated tests cover CRUD, persistence, blocked dependency behavior, and draft save/load/clear.

## Getting Started

1. Install Flutter SDK
2. From this project directory, run:

   - `flutter pub get`
   - `flutter run -d windows`

## How to delete a task

- Swipe the task card **to the right** → confirm delete → task is removed.

## Project Structure

The app is split into layers for clean separation of concerns:

```txt
lib/
├── models/    # Task model + Hive annotations
├── services/  # Box-backed CRUD and draft persistence
├── providers/ # Riverpod notifiers and loading state
├── screens/   # Full-screen UI (list, form)
├── widgets/   # Reusable UI components
└── utils/     # Shared UI helpers/constants
```

## Key files

- `lib/models/task.dart`: Task model + Hive annotations.
- `lib/models/task.g.dart`: Hive `TypeAdapter` implementations.
- `lib/services/task_service.dart`: Box-backed CRUD for tasks.
- `lib/services/task_draft_service.dart`: Hive-backed draft persistence.
- `lib/providers/task_provider.dart`: `TaskNotifier` + loading state.
- `lib/screens/task_list_screen.dart`: Task list UI with debounce search, filter, highlight, and blocked logic.
- `lib/screens/task_form_screen.dart`: Create/Edit form with validation + draft persistence.

## AI Usage Report

This project was developed with assistance from AI tools to speed up implementation and improve quality. AI was used for:

- Architecture & scaffolding (folder structure, Riverpod/Hive wiring)
- UI implementation and polish (task list, form screen, search/filter, highlight, swipe-to-delete UX)
- Bug fixing and code cleanup (analyzer warnings, API deprecations)
- Test design (unit/widget tests validating CRUD, persistence, blocked dependency logic)

All AI-generated changes were reviewed and validated with:

- `flutter analyze`
- `flutter test`

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

