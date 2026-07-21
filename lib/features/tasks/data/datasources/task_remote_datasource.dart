import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  /// Returns (tasks, total). [skip]/[limit] follow dummyjson's pagination
  /// contract; we translate 1-indexed page numbers into skip/limit upstream.
  Future<(List<TaskModel>, int total)> getTasks({required int skip, required int limit});

  Future<TaskModel> getTaskById(String id);

  Future<TaskModel> createTask(TaskModel task);

  Future<TaskModel> updateTask(TaskModel task);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final Dio dio;

  TaskRemoteDataSourceImpl(this.dio);

  @override
  Future<(List<TaskModel>, int total)> getTasks({required int skip, required int limit}) async {
    try {
      final response = await dio.get(
        ApiConstants.todosEndpoint,
        queryParameters: {'skip': skip, 'limit': limit},
      );
      final data = response.data as Map<String, dynamic>;
      final todos = (data['todos'] as List).cast<Map<String, dynamic>>();
      final total = data['total'] as int? ?? todos.length;
      final tasks = todos.map(TaskModel.fromRemoteJson).toList();
      return (tasks, total);
    } on DioException catch (e) {
      throw ServerException(_dioErrorMessage(e));
    }
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    try {
      final response = await dio.get('${ApiConstants.todoByIdEndpoint}/$id');
      return TaskModel.fromRemoteJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('Task not found.');
      }
      throw ServerException(_dioErrorMessage(e));
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      // dummyjson's /todos/add is a mock endpoint - it echoes back an object
      // with a server-assigned id but doesn't actually persist it. We treat
      // the response as an acknowledgement and keep our own richer fields
      // (priority/dueDate/etc.) client-side via the repository layer.
      final response = await dio.post(
        ApiConstants.addTodoEndpoint,
        data: {'todo': task.title, 'completed': task.status == TaskStatus.completed, 'userId': 1},
      );
      final json = response.data as Map<String, dynamic>;
      return TaskModel(
        id: json['id']?.toString() ?? task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        dueDate: task.dueDate,
        status: task.status,
        assignedUser: task.assignedUser,
      );
    } on DioException catch (e) {
      throw ServerException(_dioErrorMessage(e));
    }
  }

  @override
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      // Same caveat as createTask - dummyjson doesn't really persist PUTs
      // server-side, but the endpoint validates request/response shape,
      // which is enough to exercise real error/success handling paths.
      await dio.put(
        '${ApiConstants.todoByIdEndpoint}/${task.id}',
        data: {'todo': task.title, 'completed': task.status == TaskStatus.completed},
      );
      return task;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const NotFoundException('Task not found.');
      }
      throw ServerException(_dioErrorMessage(e));
    }
  }

  String _dioErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    return e.message ?? 'Something went wrong while contacting the server.';
  }
}
