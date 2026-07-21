import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_list/task_list_bloc.dart';
import '../widgets/state_widgets.dart';
import '../widgets/task_card.dart';
import '../widgets/task_filter_sheet.dart';
import 'create_edit_task_page.dart';
import 'task_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<TaskListBloc>().add(const TaskListRefreshRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<TaskListBloc>().add(const TaskListNextPageRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Workspace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tasks by title...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context.read<TaskListBloc>().add(const TaskListSearchChanged(''));
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      context.read<TaskListBloc>().add(TaskListSearchChanged(value));
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<TaskListBloc, TaskListState>(
                  buildWhen: (previous, current) => previous.filter != current.filter,
                  builder: (context, state) {
                    final hasFilters = state.filter.status != null || state.filter.priority != null;
                    return IconButton.filledTonal(
                      onPressed: () => showTaskFilterSheet(
                        context: context,
                        currentFilter: state.filter,
                        onStatusChanged: (status) =>
                            context.read<TaskListBloc>().add(TaskListStatusFilterChanged(status)),
                        onPriorityChanged: (priority) =>
                            context.read<TaskListBloc>().add(TaskListPriorityFilterChanged(priority)),
                        onClear: () => context.read<TaskListBloc>().add(const TaskListFiltersCleared()),
                      ),
                      icon: Icon(
                        Icons.filter_list,
                        color: hasFilters ? Theme.of(context).colorScheme.primary : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocConsumer<TaskListBloc, TaskListState>(
              listenWhen: (previous, current) =>
                  current.status == TaskListStatus.failure && current.errorMessage != null,
              listener: (context, state) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage ?? 'Something went wrong')),
                );
              },
              builder: (context, state) {
                if (state.status == TaskListStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == TaskListStatus.failure && state.allTasks.isEmpty) {
                  return ErrorStateWidget(
                    message: state.errorMessage ?? 'Failed to load tasks.',
                    onRetry: () => context.read<TaskListBloc>().add(const TaskListRefreshRequested()),
                  );
                }

                final visibleTasks = state.visibleTasks;

                if (visibleTasks.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async =>
                        context.read<TaskListBloc>().add(const TaskListRefreshRequested()),
                    child: ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyStateWidget(message: 'No tasks match your search/filters'),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TaskListBloc>().add(const TaskListRefreshRequested());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 90, top: 4),
                    itemCount: visibleTasks.length + (state.hasReachedMax ? 0 : 1),
                    itemBuilder: (context, index) {
                      if (index >= visibleTasks.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final task = visibleTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () async {
                          final updated = await Navigator.of(context).push<TaskEntity>(
                            MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
                          );
                          if (updated != null && context.mounted) {
                            context.read<TaskListBloc>().add(TaskListLocalTaskUpserted(updated));
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<TaskEntity>(
            MaterialPageRoute(builder: (_) => const CreateEditTaskPage()),
          );
          if (created != null && context.mounted) {
            context.read<TaskListBloc>().add(TaskListLocalTaskUpserted(created));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}
