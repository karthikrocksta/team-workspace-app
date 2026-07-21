part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Shown briefly while resolving the initial session on app start.
class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// Emitted right after a successful sign-up, *before* [Authenticated].
/// The UI (SignUpPage) reacts to this by showing a confirmation dialog;
/// only once the user acknowledges it does the bloc move to [Authenticated]
/// and reveal the dashboard.
class AuthSignUpSuccess extends AuthState {
  final UserEntity user;

  const AuthSignUpSuccess(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthFailureState extends AuthState {
  final String message;

  const AuthFailureState(this.message);

  @override
  List<Object?> get props => [message];
}
