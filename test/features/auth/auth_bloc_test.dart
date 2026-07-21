import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace_app/core/error/failures.dart';
import 'package:team_workspace_app/core/usecase/usecase.dart';
import 'package:team_workspace_app/features/auth/domain/entities/user_entity.dart';
import 'package:team_workspace_app/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:team_workspace_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:team_workspace_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:team_workspace_app/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:team_workspace_app/features/auth/presentation/bloc/auth_bloc.dart';

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late MockSignUpUseCase signUpUseCase;
  late MockLoginUseCase loginUseCase;
  late MockLogoutUseCase logoutUseCase;
  late MockGetCurrentUserUseCase getCurrentUserUseCase;

  const tUser = UserEntity(uid: 'uid-1', email: 'karthik@example.com');

  setUpAll(() {
    registerFallbackValue(const LoginParams(email: '', password: ''));
    registerFallbackValue(const SignUpParams(email: '', password: ''));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    signUpUseCase = MockSignUpUseCase();
    loginUseCase = MockLoginUseCase();
    logoutUseCase = MockLogoutUseCase();
    getCurrentUserUseCase = MockGetCurrentUserUseCase();
  });

  AuthBloc buildBloc() => AuthBloc(
        signUpUseCase: signUpUseCase,
        loginUseCase: loginUseCase,
        logoutUseCase: logoutUseCase,
        getCurrentUserUseCase: getCurrentUserUseCase,
      );

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when a session already exists',
      setUp: () {
        when(() => getCurrentUserUseCase(any())).thenAnswer((_) async => const Right(tUser));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] when there is no session',
      setUp: () {
        when(() => getCurrentUserUseCase(any())).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  group('AuthLoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful login',
      setUp: () {
        when(() => loginUseCase(any())).thenAnswer((_) async => const Right(tUser));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLoginRequested(email: 'karthik@example.com', password: 'secret1')),
      expect: () => [const AuthLoading(), const Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] on invalid credentials',
      setUp: () {
        when(() => loginUseCase(any()))
            .thenAnswer((_) async => const Left(AuthFailure('Incorrect email or password.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLoginRequested(email: 'karthik@example.com', password: 'wrong')),
      expect: () => [const AuthLoading(), const AuthFailureState('Incorrect email or password.')],
    );
  });

  group('AuthSignUpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSignUpSuccess] on successful sign up (does NOT '
      'go straight to Authenticated - confirmation is required first)',
      setUp: () {
        when(() => signUpUseCase(any())).thenAnswer((_) async => const Right(tUser));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignUpRequested(email: 'karthik@example.com', password: 'secret1')),
      expect: () => [const AuthLoading(), const AuthSignUpSuccess(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailureState] when the email is already in use',
      setUp: () {
        when(() => signUpUseCase(any()))
            .thenAnswer((_) async => const Left(AuthFailure('An account already exists for that email.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignUpRequested(email: 'karthik@example.com', password: 'secret1')),
      expect: () => [const AuthLoading(), const AuthFailureState('An account already exists for that email.')],
    );

    blocTest<AuthBloc, AuthState>(
      'moves from AuthSignUpSuccess to Authenticated once AuthSignUpConfirmed is dispatched',
      setUp: () {
        when(() => signUpUseCase(any())).thenAnswer((_) async => const Right(tUser));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const AuthSignUpRequested(email: 'karthik@example.com', password: 'secret1'));
        await Future.delayed(const Duration(milliseconds: 10));
        bloc.add(const AuthSignUpConfirmed());
      },
      expect: () => [const AuthLoading(), const AuthSignUpSuccess(tUser), const Authenticated(tUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'ignores AuthSignUpConfirmed if there is no pending AuthSignUpSuccess state',
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthSignUpConfirmed()),
      expect: () => <AuthState>[],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Unauthenticated] on logout',
      setUp: () {
        when(() => logoutUseCase(any())).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });
}
