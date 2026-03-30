# Task Manager App

A real-world Flutter task management app with clean architecture, polished UI/UX, and reliable local persistence.

## Features (implemented)

### Task management (Hive + Riverpod)
- Task model persisted locally in Hive (`tasks` box).
- CRUD operations via `TaskService`.
- Riverpod `TaskNotifier` manages loading state and prevents duplicate submissions.
- Create/Edit form with draft persistence:
  - Draft auto-saves when you leave the screen.
  - Draft restores when you reopen Create/Edit.
  - Drafts are stored in Hive (`task_drafts` box).

### Search + Filter + Highlight
- Debounced (300ms) search by task title (case-insensitive).
- Status filter: All, ToDo, InProgress, Done.
- Matching title text is highlighted using `RichText`/`TextSpan`.

### Blocked task UX
- If a task is blocked by another task that is not `Done`:
  - Card is greyed out.
  - Interaction is disabled.
  - Card shows `Blocked by: <Task Title>`.

## UI polish

- Rounded cards with soft shadows and clear visual hierarchy (title > date > status).
- Subtle list animations and lightweight card transitions.
- Loading indicators on the task list and Save/Update button.
- Empty states:
  - `No tasks yet. Create your first task!`
  - `No tasks match your search`

## Tech Stack

- Flutter
- Material 3
- Riverpod (StateNotifier)
- Hive (local persistence)
- Intl (date formatting)
- uuid (Task id generation)

## Getting Started

1. Install Flutter SDK
2. From this project directory, run:
   - `flutter pub get`
   - `flutter run -d windows`

## Project Structure

The app is split into layers for clean separation of concerns:

- `lib/models/`
- `lib/services/`
- `lib/providers/`
- `lib/screens/`
- `lib/widgets/`
- `lib/utils/`

### Key files
- `lib/models/task.dart`: Task model + Hive annotations.
- `lib/models/task.g.dart`: Hive `TypeAdapter` implementations.
- `lib/services/task_service.dart`: Box-backed CRUD for tasks.
- `lib/services/task_draft_service.dart`: Hive-backed draft persistence.
- `lib/providers/task_provider.dart`: `TaskNotifier` + loading state.
- `lib/screens/task_list_screen.dart`: Task list UI with debounce search, filter, highlight, and blocked logic.
- `lib/screens/task_form_screen.dart`: Create/Edit form with validation + draft persistence.
