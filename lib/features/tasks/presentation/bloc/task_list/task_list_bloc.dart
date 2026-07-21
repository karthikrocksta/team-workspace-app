import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../domain/entities/task_entity.dart';
import '../../../domain/entities/task_filter.dart';
import '../../../domain/usecases/get_tasks_usecase.dart';

part 'task_list_event.dart';
part 'task_list_state.dart';

class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final GetTasksUseCase getTasksUseCase;

  TaskListBloc({required this.getTasksUseCase}) : super(const TaskListState()) {
    on<TaskListRefreshRequested>(_onRefresh);
    on<TaskListNextPageRequested>(_onNextPage);
    on<TaskListSearchChanged>(_onSearchChanged);
    on<TaskListStatusFilterChanged>(_onStatusFilterChanged);
    on<TaskListPriorityFilterChanged>(_onPriorityFilterChanged);
    on<TaskListFiltersCleared>(_onFiltersCleared);
    on<TaskListLocalTaskUpserted>(_onLocalTaskUpserted);
  }

  Future<void> _onRefresh(TaskListRefreshRequested event, Emitter<TaskListState> emit) async {
    emit(state.copyWith(status: TaskListStatus.loading, clearError: true));
    final result = await getTasksUseCase(
      const GetTasksParams(page: 1, pageSize: ApiConstants.defaultPageSize),
    );
    result.fold(
      (failure) => emit(state.copyWith(status: TaskListStatus.failure, errorMessage: failure.message)),
      (page) => emit(
        state.copyWith(
          status: TaskListStatus.success,
          allTasks: page.tasks,
          hasReachedMax: page.hasReachedMax,
          currentPage: 1,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onNextPage(TaskListNextPageRequested event, Emitter<TaskListState> emit) async {
    if (state.hasReachedMax || state.status == TaskListStatus.loadingMore) return;

    emit(state.copyWith(status: TaskListStatus.loadingMore));
    final nextPage = state.currentPage + 1;
    final result = await getTasksUseCase(
      GetTasksParams(page: nextPage, pageSize: ApiConstants.defaultPageSize),
    );
    result.fold(
      (failure) => emit(state.copyWith(status: TaskListStatus.success, errorMessage: failure.message)),
      (page) => emit(
        state.copyWith(
          status: TaskListStatus.success,
          allTasks: [...state.allTasks, ...page.tasks],
          hasReachedMax: page.hasReachedMax,
          currentPage: nextPage,
          clearError: true,
        ),
      ),
    );
  }

  void _onSearchChanged(TaskListSearchChanged event, Emitter<TaskListState> emit) {
    emit(state.copyWith(filter: state.filter.copyWith(query: event.query)));
  }

  void _onStatusFilterChanged(TaskListStatusFilterChanged event, Emitter<TaskListState> emit) {
    emit(state.copyWith(
      filter: state.filter.copyWith(status: event.status, clearStatus: event.status == null),
    ));
  }

  void _onPriorityFilterChanged(TaskListPriorityFilterChanged event, Emitter<TaskListState> emit) {
    emit(state.copyWith(
      filter: state.filter.copyWith(priority: event.priority, clearPriority: event.priority == null),
    ));
  }

  void _onFiltersCleared(TaskListFiltersCleared event, Emitter<TaskListState> emit) {
    emit(state.copyWith(filter: const TaskFilter()));
  }

  void _onLocalTaskUpserted(TaskListLocalTaskUpserted event, Emitter<TaskListState> emit) {
    final tasks = [...state.allTasks];
    final index = tasks.indexWhere((t) => t.id == event.task.id);
    if (index >= 0) {
      tasks[index] = event.task;
    } else {
      tasks.insert(0, event.task);
    }
    emit(state.copyWith(allTasks: tasks));
  }
}
