import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_detail/task_detail_bloc.dart';
import '../widgets/state_widgets.dart';
import '../widgets/task_badges.dart';
import 'create_edit_task_page.dart';

class TaskDetailPage extends StatelessWidget {
  final TaskEntity task;

  const TaskDetailPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskDetailBloc>()..add(TaskDetailSeeded(task)),
      child: _TaskDetailView(initialTask: task),
    );
  }
}

class _TaskDetailView extends StatelessWidget {
  final TaskEntity initialTask;

  const _TaskDetailView({required this.initialTask});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          BlocBuilder<TaskDetailBloc, TaskDetailState>(
            builder: (context, state) {
              if (state is! TaskDetailLoaded) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final updated = await Navigator.of(context).push<TaskEntity>(
                    MaterialPageRoute(builder: (_) => CreateEditTaskPage(existingTask: state.task)),
                  );
                  if (updated != null && context.mounted) {
                    // ignore: use_build_context_synchronously
                    context.read<TaskDetailBloc>().add(TaskDetailSeeded(updated));
                  }
                },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TaskDetailBloc, TaskDetailState>(
        listener: (context, state) {
          if (state is TaskDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TaskDetailError) {
            return ErrorStateWidget(
              message: state.message,
              onRetry: () =>
                  context.read<TaskDetailBloc>().add(TaskDetailLoadRequested(initialTask.id)),
            );
          }

          final task = (state as TaskDetailLoaded).task;
          final isCompleted = task.status == TaskStatus.completed;

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) Navigator.of(context).pop(task);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PriorityBadge(priority: task.priority),
                      const SizedBox(width: 8),
                      StatusBadge(status: task.status),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(task.description, style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 20),
                  _DetailRow(icon: Icons.calendar_today_outlined, label: 'Due date', value: DateFormat.yMMMMd().format(task.dueDate)),
                  const SizedBox(height: 12),
                  _DetailRow(icon: Icons.person_outline, label: 'Assigned to', value: task.assignedUser),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isUpdating
                          ? null
                          : () => context.read<TaskDetailBloc>().add(const TaskDetailStatusToggled()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.grey.shade700 : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: state.isUpdating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(isCompleted ? Icons.replay : Icons.check_circle_outline),
                      label: Text(isCompleted ? 'Reopen Task' : 'Mark as Completed'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    );
  }
}
