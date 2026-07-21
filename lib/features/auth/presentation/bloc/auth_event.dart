part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched once on app start to check whether a session already exists.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Dispatched after the user acknowledges the "Account created" confirmation
/// dialog, moving them from [AuthSignUpSuccess] into the app proper
/// ([Authenticated]). Keeping this as a separate step (rather than going
/// straight to Authenticated on sign-up) lets the UI show an explicit
/// confirmation before the dashboard appears.
class AuthSignUpConfirmed extends AuthEvent {
  const AuthSignUpConfirmed();
}
