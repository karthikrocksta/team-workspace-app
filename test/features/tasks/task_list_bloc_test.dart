import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace_app/core/error/failures.dart';
import 'package:team_workspace_app/features/tasks/domain/entities/task_entity.dart';
import 'package:team_workspace_app/features/tasks/domain/entities/task_page.dart';
import 'package:team_workspace_app/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:team_workspace_app/features/tasks/presentation/bloc/task_list/task_list_bloc.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

TaskEntity _task(String id, {String title = 'Sample task', TaskStatus status = TaskStatus.pending}) {
  return TaskEntity(
    id: id,
    title: title,
    description: 'desc',
    priority: TaskPriority.medium,
    dueDate: DateTime(2026, 1, 1),
    status: status,
    assignedUser: 'Karthik',
  );
}

void main() {
  late MockGetTasksUseCase getTasksUseCase;

  setUpAll(() {
    registerFallbackValue(const GetTasksParams(page: 1, pageSize: 10));
  });

  setUp(() {
    getTasksUseCase = MockGetTasksUseCase();
  });

  TaskListBloc buildBloc() => TaskListBloc(getTasksUseCase: getTasksUseCase);

  blocTest<TaskListBloc, TaskListState>(
    'emits [loading, success] with tasks on TaskListRefreshRequested',
    setUp: () {
      when(() => getTasksUseCase(any())).thenAnswer(
        (_) async => Right(TaskPage(tasks: [_task('1'), _task('2')], total: 2, hasReachedMax: true)),
      );
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const TaskListRefreshRequested()),
    expect: () => [
      predicate<TaskListState>((s) => s.status == TaskListStatus.loading),
      predicate<TaskListState>((s) => s.status == TaskListStatus.success && s.allTasks.length == 2),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'emits [loading, failure] when the use case fails',
    setUp: () {
      when(() => getTasksUseCase(any())).thenAnswer((_) async => const Left(NetworkFailure()));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const TaskListRefreshRequested()),
    expect: () => [
      predicate<TaskListState>((s) => s.status == TaskListStatus.loading),
      predicate<TaskListState>((s) => s.status == TaskListStatus.failure),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'appends the next page and respects hasReachedMax',
    setUp: () {
      when(() => getTasksUseCase(const GetTasksParams(page: 1, pageSize: 10))).thenAnswer(
        (_) async => Right(TaskPage(tasks: [_task('1')], total: 2, hasReachedMax: false)),
      );
      when(() => getTasksUseCase(const GetTasksParams(page: 2, pageSize: 10))).thenAnswer(
        (_) async => Right(TaskPage(tasks: [_task('2')], total: 2, hasReachedMax: true)),
      );
    },
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const TaskListRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 10));
      bloc.add(const TaskListNextPageRequested());
    },
    skip: 2,
    expect: () => [
      predicate<TaskListState>((s) => s.status == TaskListStatus.loadingMore),
      predicate<TaskListState>((s) => s.allTasks.length == 2 && s.hasReachedMax),
    ],
  );

  blocTest<TaskListBloc, TaskListState>(
    'search and status filter narrow down visibleTasks together',
    setUp: () {
      when(() => getTasksUseCase(any())).thenAnswer(
        (_) async => Right(TaskPage(
          tasks: [
            _task('1', title: 'Fix login bug', status: TaskStatus.pending),
            _task('2', title: 'Fix logout bug', status: TaskStatus.completed),
            _task('3', title: 'Write docs', status: TaskStatus.pending),
          ],
          total: 3,
          hasReachedMax: true,
        )),
      );
    },
    build: buildBloc,
    act: (bloc) {
      bloc.add(const TaskListRefreshRequested());
      bloc.add(const TaskListSearchChanged('fix'));
      bloc.add(const TaskListStatusFilterChanged(TaskStatus.pending));
    },
    verify: (bloc) {
      expect(bloc.state.visibleTasks.length, 1);
      expect(bloc.state.visibleTasks.first.id, '1');
    },
  );
}
