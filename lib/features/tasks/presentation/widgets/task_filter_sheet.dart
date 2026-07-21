import 'package:flutter/material.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_filter.dart';

Future<void> showTaskFilterSheet({
  required BuildContext context,
  required TaskFilter currentFilter,
  required ValueChanged<TaskStatus?> onStatusChanged,
  required ValueChanged<TaskPriority?> onPriorityChanged,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          TaskStatus? selectedStatus = currentFilter.status;
          TaskPriority? selectedPriority = currentFilter.priority;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        onClear();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskStatus.values.map((status) {
                    final selected = selectedStatus == status;
                    return ChoiceChip(
                      label: Text(status.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => selectedStatus = selected ? null : status);
                        onStatusChanged(selected ? null : status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: TaskPriority.values.map((priority) {
                    final selected = selectedPriority == priority;
                    return ChoiceChip(
                      label: Text(priority.label),
                      selected: selected,
                      onSelected: (_) {
                        setState(() => selectedPriority = selected ? null : priority);
                        onPriorityChanged(selected ? null : priority);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
