import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box box;

  AuthLocalDataSourceImpl(this.box);

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      await box.put(HiveKeys.cachedUser, jsonEncode(user.toJson()));
    } catch (_) {
      throw const CacheException('Failed to persist user session.');
    }
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final raw = box.get(HiveKeys.cachedUser) as String?;
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCachedUser() async {
    await box.delete(HiveKeys.cachedUser);
  }
}
