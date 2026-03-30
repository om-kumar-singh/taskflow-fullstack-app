# Task Manager App

> A real-world Flutter task management app with clean architecture, polished UI/UX, and reliable local persistence.

---

## Demo

https://github.com/user-attachments/assets/ecc66f32-5b29-4de3-a4b4-f2ab58e15e55

---

## Features

### Task Management · Hive + Riverpod
- Tasks are persisted locally in a Hive `tasks` box.
- Full CRUD via `TaskService`.
- `TaskNotifier` (Riverpod `StateNotifier`) manages loading state and prevents duplicate submissions.
- **Draft persistence** on the Create/Edit form:
  - Draft auto-saves when you leave the screen.
  - Draft restores when you reopen Create/Edit.
  - Drafts live in a separate Hive `task_drafts` box.

### Search, Filter & Highlight
- Debounced (300ms) search by task title — case-insensitive.
- Status filter: **All · ToDo · InProgress · Done**.
- Matching text is highlighted inline using `RichText` / `TextSpan`.

### Blocked Task UX
If a task is blocked by another task that is not `Done`:
- The card is greyed out and interaction is disabled.
- The card shows **Blocked by: \<Task Title\>**.

### UI Polish
- Rounded cards with soft shadows and clear visual hierarchy — title → date → status.
- Subtle list animations and lightweight card transitions.
- Loading indicators on the task list and the Save/Update button.
- Friendly empty states:
  - *No tasks yet. Create your first task!*
  - *No tasks match your search.*

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter · Material 3 |
| State Management | Riverpod (StateNotifier) |
| Local Persistence | Hive |
| Date Formatting | intl |
| ID Generation | uuid |

---

## Getting Started

**Prerequisites:** [Flutter SDK](https://docs.flutter.dev/get-started/install)

```bash
# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on other platforms
flutter run -d <device>
```

---

## Project Structure

```
lib/
├── models/          # Task model + Hive annotations
├── services/        # Box-backed CRUD and draft persistence
├── providers/       # Riverpod notifiers and state
├── screens/         # Full-screen UI (list, form)
├── widgets/         # Reusable UI components
└── utils/           # Helpers and utilities
```

### Key Files

| File | Responsibility |
|---|---|
| `lib/models/task.dart` | Task model + Hive annotations |
| `lib/models/task.g.dart` | Generated Hive `TypeAdapter` |
| `lib/services/task_service.dart` | CRUD operations against the Hive box |
| `lib/services/task_draft_service.dart` | Hive-backed draft persistence |
| `lib/providers/task_provider.dart` | `TaskNotifier` + loading state |
| `lib/screens/task_list_screen.dart` | List UI — search, filter, highlight, blocked logic |
| `lib/screens/task_form_screen.dart` | Create/Edit form — validation + draft persistence |

---

## License

This project is open source. See [LICENSE](LICENSE) for details.
