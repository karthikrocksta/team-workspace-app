import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/tasks/presentation/bloc/task_list/task_list_bloc.dart';
import 'features/tasks/presentation/pages/dashboard_page.dart';

class TeamWorkspaceApp extends StatelessWidget {
  const TeamWorkspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested())),
      ],
      child: MaterialApp(
        title: 'Team Workspace',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(filled: false),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

/// Decides whether to show the Login flow or the authenticated Dashboard,
/// reacting live to [AuthBloc] state (login, logout, and session restore
/// on cold start are all funneled through the same state machine).
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          return BlocProvider(
            create: (_) => sl<TaskListBloc>(),
            child: const DashboardPage(),
          );
        }
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return const LoginPage();
      },
    );
  }
}
