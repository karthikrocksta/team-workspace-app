import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignUpUseCase signUpUseCase;
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.signUpUseCase,
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSignUpConfirmed>(_onSignUpConfirmed);
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) => emit(const Unauthenticated()),
      (user) => emit(user != null ? Authenticated(user) : const Unauthenticated()),
    );
  }

  Future<void> _onSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await signUpUseCase(SignUpParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      // Gate on a confirmation step rather than going straight to
      // Authenticated - the SignUpPage shows a dialog and dispatches
      // AuthSignUpConfirmed once the user acknowledges it.
      (user) => emit(AuthSignUpSuccess(user)),
    );
  }

  void _onSignUpConfirmed(AuthSignUpConfirmed event, Emitter<AuthState> emit) {
    final current = state;
    if (current is AuthSignUpSuccess) {
      emit(Authenticated(current.user));
    }
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginUseCase(LoginParams(email: event.email, password: event.password));
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await logoutUseCase(const NoParams());
    result.fold(
      (failure) => emit(AuthFailureState(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }
}
