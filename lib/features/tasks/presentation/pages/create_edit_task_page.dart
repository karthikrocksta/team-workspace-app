import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/task_entity.dart';
import '../bloc/task_form/task_form_bloc.dart';

class CreateEditTaskPage extends StatelessWidget {
  final TaskEntity? existingTask;

  const CreateEditTaskPage({super.key, this.existingTask});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TaskFormBloc>(),
      child: _CreateEditTaskView(existingTask: existingTask),
    );
  }
}

class _CreateEditTaskView extends StatefulWidget {
  final TaskEntity? existingTask;

  const _CreateEditTaskView({this.existingTask});

  @override
  State<_CreateEditTaskView> createState() => _CreateEditTaskViewState();
}

class _CreateEditTaskViewState extends State<_CreateEditTaskView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _dueDate;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.pending;
    _dueDate = task?.dueDate ?? DateTime.now().add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final task = TaskEntity(
      id: widget.existingTask?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDate: _dueDate,
      status: _status,
      assignedUser: widget.existingTask?.assignedUser ?? 'Karthik (You)',
    );

    context.read<TaskFormBloc>().add(TaskFormSubmitted(task: task, isEditing: _isEditing));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Task' : 'Create Task')),
      body: BlocListener<TaskFormBloc, TaskFormState>(
        listener: (context, state) {
          if (state is TaskFormSuccess) {
            Navigator.of(context).pop(state.task);
          } else if (state is TaskFormFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    validator: (value) => Validators.required(value, fieldName: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration:
                        const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                    validator: (value) => Validators.required(value, fieldName: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                    items: TaskPriority.values
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                        .toList(),
                    onChanged: (value) => setState(() => _priority = value ?? _priority),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    DropdownButtonFormField<TaskStatus>(
                      value: _status,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: TaskStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                          .toList(),
                      onChanged: (value) => setState(() => _status = value ?? _status),
                    ),
                  if (_isEditing) const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Due date', border: OutlineInputBorder()),
                      child: Text(DateFormat.yMMMd().format(_dueDate)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  BlocBuilder<TaskFormBloc, TaskFormState>(
                    builder: (context, state) {
                      final isSubmitting = state is TaskFormSubmitting;
                      return ElevatedButton(
                        onPressed: isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(_isEditing ? 'Save Changes' : 'Create Task'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
