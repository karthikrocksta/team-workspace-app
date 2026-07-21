# Team Workspace App

A lightweight Flutter "Team Workspace" app built for the **Tech Transient — Flutter Machine Test**.
Authenticated users can browse, search, filter, create, edit, and complete project tasks, backed by
Firebase Authentication and a paginated public REST API.

The assessment explicitly deprioritizes UI polish in favor of **Clean Architecture, Bloc, Dependency
Injection, API integration/pagination, and error handling** — this README explains how each of those
requirements was addressed.

---

## 1. Setup Instructions

### Prerequisites
- Flutter (latest stable channel) — `flutter --version`
- A Firebase project with **Email/Password** sign-in enabled
- The [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) (`dart pub global activate flutterfire_cli`)

### Steps

```bash
# 1. Get packages
flutter pub get

# 2. Scaffold native platform folders (android/, ios/) — not committed to this repo
flutter create .

# 3. Configure Firebase for this app
firebase login
flutterfire configure
# This overwrites lib/firebase_options.dart with real values for your project
# and drops google-services.json / GoogleService-Info.plist into android/ and ios/.

# 4. In the Firebase console, enable Authentication -> Sign-in method -> Email/Password

# 5. Run the app
flutter run
```

### Running tests
```bash
flutter test
```

> **Note:** `lib/firebase_options.dart` in this repo is a **placeholder** (see the file for details) —
> it intentionally throws until you run `flutterfire configure` against your own Firebase project. This
> keeps real project credentials out of the public repository, per the assessment's notes on not
> committing sensitive credentials.

---

## 2. Architecture Overview

The project follows **Clean Architecture** with a **feature-first** folder structure:

```
lib/
├── core/                     # Cross-cutting concerns shared by all features
│   ├── di/                   # GetIt service locator (injection.dart)
│   ├── error/                 # Failure (domain) / Exception (data) types
│   ├── network/               # Dio client, connectivity abstraction
│   ├── usecase/                # Base UseCase<Type, Params> contract
│   ├── constants/              # API endpoints, Hive box/key names
│   └── utils/                  # Logger, form validators
│
├── features/
│   ├── auth/
│   │   ├── domain/            # UserEntity, AuthRepository (abstract), use cases
│   │   ├── data/               # UserModel, FirebaseAuthDataSource, Hive session cache,
│   │   │                       # AuthRepositoryImpl
│   │   └── presentation/       # AuthBloc, Login/SignUp pages, shared widgets
│   │
│   └── tasks/
│       ├── domain/             # TaskEntity, TaskPage, TaskFilter, TaskRepository (abstract),
│       │                       # GetTasks/GetTaskById/CreateTask/UpdateTask use cases
│       ├── data/                # TaskModel, Dio remote data source, Hive local data source,
│       │                        # TaskRepositoryImpl (merges remote + cache + offline queue)
│       └── presentation/        # 3 Blocs (list/detail/form), Dashboard/Detail/Create-Edit pages
│
├── app.dart                    # MaterialApp + auth-gated routing (AuthBloc-driven)
└── main.dart                   # Bootstraps Firebase, Hive, DI, connectivity-based sync
```

**Dependency rule:** `presentation → domain ← data`. The `domain` layer (entities, repository
*interfaces*, use cases) has zero dependencies on Flutter, Dio, Firebase, or Hive — it only depends on
`dartz`/`equatable`. This is what makes the Bloc layer and use cases independently unit-testable (see
`test/`), and is why swapping the backend (e.g. dummyjson → a real company API) only touches the `data`
layer.

### State management — flutter_bloc
Three Blocs power the Tasks feature, kept intentionally separate since each has a distinct lifecycle:
- **`TaskListBloc`** — dashboard: pagination (`hasReachedMax`, page cursor), pull-to-refresh, and a
  `TaskFilter` (search text + status + priority) applied together via a derived `visibleTasks` getter.
- **`TaskDetailBloc`** — loads/holds a single task, and optimistically flips its status
  (mark complete / reopen) via `UpdateTaskUseCase`.
- **`TaskFormBloc`** — shared by both the Create and Edit screens (`isEditing` flag decides whether it
  calls `CreateTaskUseCase` or `UpdateTaskUseCase`).

`AuthBloc` owns the whole app's auth state machine (`AuthInitial → AuthLoading → Authenticated |
Unauthenticated`), and `app.dart`'s `_AuthGate` widget switches between the Login flow and the Dashboard
purely by listening to it — including automatically resuming a session on cold start via
`AuthCheckRequested`.

### Dependency Injection — GetIt
`core/di/injection.dart` wires every layer (`initDependencies()`, called once in `main()` before
`runApp`). Data sources, repositories, and use cases are registered as lazy singletons; Blocs are
registered as **factories** so each screen gets its own fresh instance (avoids stale state when
navigating back and forth, e.g. Create Task after Create Task).

### Error handling
- Data sources throw typed `Exception`s (`ServerException`, `NetworkException`, `CacheException`,
  `AuthException`, `NotFoundException`) — `core/error/exceptions.dart`.
- Repositories catch those and convert them into typed `Failure`s (`core/error/failures.dart`), returned
  via `Either<Failure, T>` (`dartz`). The presentation layer never sees a raw Dio/Firebase/Hive
  exception — Blocs simply `fold` the `Either` into a UI state with a human-readable message.
- Firebase error codes (`email-already-in-use`, `wrong-password`, `weak-password`, etc.) are mapped to
  plain-English messages in `FirebaseAuthDataSourceImpl._mapFirebaseError`.

---

## 3. Feature-to-Requirement Mapping

| Requirement | Where it lives |
|---|---|
| Firebase email/password auth, loading/error states, session persistence | `features/auth/*`, `AuthBloc`, `AuthLocalDataSource` (Hive cache mirrors Firebase's own session restore) |
| Paginated dashboard, infinite scroll, pull-to-refresh, loading/empty/error + retry | `TaskListBloc` + `DashboardPage` (scroll-listener triggers `TaskListNextPageRequested`) |
| Task details, mark complete/reopen, instant UI reflection | `TaskDetailBloc`, `TaskDetailPage` (pops the updated task back to the dashboard, which upserts it locally) |
| Create Task, validation, success/error handling, appears without restart | `TaskFormBloc` + `CreateEditTaskPage`; Dashboard listens for the popped task and calls `TaskListLocalTaskUpserted` |
| Edit Task (all fields incl. status) | Same `CreateEditTaskPage`, `existingTask` param toggles `isEditing` |
| Search by title + status/priority filters, working together | `TaskFilter` value object + `TaskListState.visibleTasks` getter |
| Offline persistence of session + last loaded task list | Hive boxes (`auth_session_box`, `task_cache_box`) via `AuthLocalDataSource` / `TaskLocalDataSource` |
| **Bonus:** offline-created/edited task sync on reconnect | `TaskLocalDataSource` pending-sync queue + `TaskRepositoryImpl.syncPendingChanges()`, triggered by a `connectivity_plus` listener in `main.dart` |
| **Bonus:** unit tests | `test/features/auth/auth_bloc_test.dart`, `test/features/tasks/task_list_bloc_test.dart` (bloc_test + mocktail) |
| **Bonus:** logging | `core/utils/app_logger.dart` (centralizes `dart:developer` logging; swappable for Crashlytics/Sentry) |

---

## 4. Packages Used

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (Bloc pattern) |
| `equatable` | Value equality for entities/events/states |
| `get_it` | Dependency injection / service locator |
| `dio` | HTTP client for the REST API |
| `connectivity_plus` | Connectivity checks (offline fallback + sync trigger) |
| `firebase_core`, `firebase_auth` | Firebase Authentication |
| `hive`, `hive_flutter` | Lightweight local persistence (session cache, task cache, offline queue) |
| `intl` | Date formatting |
| `uuid` | Client-generated IDs for offline-created tasks |
| `dartz` | `Either<Failure, T>` for functional error handling |
| `bloc_test`, `mocktail` (dev) | Bloc/unit testing |

---

## 5. API Used

The dashboard is backed by the public **[dummyjson.com](https://dummyjson.com/docs/todos)** `/todos`
endpoint (`GET /todos?skip=&limit=`), which supports real skip/limit pagination and a realistic
success/error/timeout surface via Dio.

`dummyjson` only returns `id`, `todo`, `completed`, and `userId` — it doesn't model priority, due dates,
or assignees. Per the assessment's note that *"mock data is acceptable"* for the assigned user, those
extra fields (**priority, due date, assignee**) are derived **deterministically from each task's id** in
`TaskModel.fromRemoteJson`, so the same task always looks identical across refreshes/pages instead of
randomizing on every load.

`POST /todos/add` and `PUT /todos/{id}` are real, working endpoints on dummyjson (they validate/echo the
request) but the service doesn't actually persist changes server-side. `TaskRepositoryImpl` therefore
treats a successful response as an **acknowledgement** and keeps the richer task object (with our
generated id/fields) in the local Hive cache as the source of truth — which is what makes "new task
appears on the dashboard without restarting the app" work reliably.

---

## 6. Assumptions Made

1. **Backend**: No company-specific backend was provided, so a public REST API (dummyjson) was used, as
   explicitly permitted by the assessment ("REST API (preferred) or local JSON"). The repository
   pattern isolates this choice — swapping in a real backend only requires changing
   `TaskRemoteDataSourceImpl`.
2. **Assigned user**: Since the API has no concept of task assignees, a small deterministic mock roster
   is used (per the assessment's "mock data is acceptable" note). The Create/Edit form defaults new
   tasks to "Karthik (You)".
3. **Priority/due date on create**: The Create Task form lets the user pick these explicitly; only
   tasks *fetched from the API* have them derived, since the API itself doesn't provide them.
4. **"Search tasks by title" + filters "work together"**: Interpreted as an AND — a task must match the
   search text AND the selected status AND the selected priority (when set) to be shown.
5. **Offline behavior**: When there's no connectivity, the dashboard shows the last cached page(s) plus
   any locally created/edited tasks, with pagination disabled (`hasReachedMax = true`) until back
   online — since dummyjson has no true offline copy of "later" pages to fall back to.
6. **Firebase project**: Since this is a public repository, no real Firebase project credentials are
   committed. `flutterfire configure` must be run against your own Firebase project before the app can
   authenticate (see Setup Instructions).

---

## 7. What's Intentionally Out of Scope

Per the assessment's own guidance to prioritize architecture/state/code quality over visual design, the
UI uses stock Material 3 widgets with minimal custom theming. Dark mode, CI/CD, and flavors were left
out to keep the review focused on the mandatory technical requirements above.
