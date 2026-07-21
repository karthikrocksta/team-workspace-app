import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signUp({required String email, required String password});

  Future<Either<Failure, UserEntity>> login({required String email, required String password});

  Future<Either<Failure, void>> logout();

  /// Returns the currently authenticated user, checking the live Firebase
  /// stream first and falling back to the locally cached session (Hive) so
  /// the app can restore a "logged in" UI state instantly on cold start,
  /// even before Firebase has finished restoring its own session.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}
