import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/login_screen.dart';

void main() {
  // Initialize core services
  final apiClient = ApiClient(baseUrl: 'http://localhost:3000/api/v1');
  final authRepository = AuthRepository(apiClient: apiClient);

  runApp(ComandixApp(authRepository: authRepository));
}

class ComandixApp extends StatelessWidget {
  final AuthRepository authRepository;

  const ComandixApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository)..add(AuthCheckRequested()),
        ),
      ],
      child: MaterialApp(
        title: 'Comandix POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF3498DB),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Inter',
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // TODO: Return Main POS Screen here
              return const Scaffold(
                body: Center(
                  child: Text(
                    'POS MAIN SCREEN\n(Autenticado exitosamente)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
