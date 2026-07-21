import '../../domain/entities/task_entity.dart';

/// dummyjson.com's `/todos` endpoint only returns `id`, `todo`, `completed`,
/// and `userId`. Since the assessment allows "mock data" for fields the
/// public API doesn't provide (assigned user, priority, due date), we derive
/// those deterministically from the todo's `id` so the same task always
/// renders identically across pages/refreshes.
class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.priority,
    required super.dueDate,
    required super.status,
    required super.assignedUser,
    super.isLocalOnly,
  });

  factory TaskModel.fromRemoteJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final title = json['todo'] as String? ?? 'Untitled task';
    final completed = json['completed'] as bool? ?? false;
    final idNum = int.tryParse(id) ?? 0;

    return TaskModel(
      id: id,
      title: title,
      description: 'Auto-generated task synced from the workspace backlog (item #$id).',
      priority: _derivePriority(idNum),
      dueDate: DateTime.now().add(Duration(days: (idNum % 14) - 3)),
      status: completed ? TaskStatus.completed : _deriveStatus(idNum),
      assignedUser: _deriveAssignee(idNum),
    );
  }

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      priority: entity.priority,
      dueDate: entity.dueDate,
      status: entity.status,
      assignedUser: entity.assignedUser,
      isLocalOnly: entity.isLocalOnly,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: TaskPriority.values.byName(json['priority'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: TaskStatus.values.byName(json['status'] as String),
      assignedUser: json['assignedUser'] as String,
      isLocalOnly: json['isLocalOnly'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'assignedUser': assignedUser,
      'isLocalOnly': isLocalOnly,
    };
  }

  static TaskPriority _derivePriority(int id) {
    final mod = id % 3;
    if (mod == 0) return TaskPriority.high;
    if (mod == 1) return TaskPriority.medium;
    return TaskPriority.low;
  }

  static TaskStatus _deriveStatus(int id) {
    return id % 2 == 0 ? TaskStatus.inProgress : TaskStatus.pending;
  }

  static const _mockAssignees = ['Aditi Rao', 'Karthik Nair', 'Priya Sharma', 'Rohan Mehta', 'Sara Khan'];

  static String _deriveAssignee(int id) => _mockAssignees[id % _mockAssignees.length];
}
