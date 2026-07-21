import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({required this.remoteDataSource, required this.localDataSource});

  @override
  Future<Either<Failure, UserEntity>> signUp({required String email, required String password}) async {
    try {
      final user = await remoteDataSource.signUp(email: email, password: password);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected sign up error', error: e);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> login({required String email, required String password}) async {
    try {
      final user = await remoteDataSource.login(email: email, password: password);
      await localDataSource.cacheUser(user);
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      AppLogger.error('Unexpected login error', error: e);
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCachedUser();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Logout failed', error: e);
      return const Left(UnknownFailure('Failed to log out. Please try again.'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      // Prefer the live Firebase user (source of truth).
      final remoteUser = remoteDataSource.currentUser;
      if (remoteUser != null) {
        await localDataSource.cacheUser(remoteUser);
        return Right(remoteUser);
      }
      // Fall back to the cached session, e.g. while Firebase is still
      // rehydrating on a cold start, or fully offline.
      final cachedUser = await localDataSource.getCachedUser();
      return Right(cachedUser);
    } catch (e) {
      AppLogger.error('Failed to resolve current user', error: e);
      return const Left(CacheFailure());
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;
}
