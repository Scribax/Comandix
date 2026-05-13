import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_client.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/pos/pos_main_screen.dart';

import 'features/pos/pos_repository.dart';
import 'features/pos/bloc/pos_bloc.dart';
import 'features/pos/bloc/pos_event.dart';

void main() {
  // Initialize core services
  final apiClient = ApiClient(baseUrl: 'http://186.64.123.116/api/v1');
  final authRepository = AuthRepository(apiClient: apiClient);
  final posRepository = PosRepository(apiClient: apiClient);

  runApp(ComandixApp(
    authRepository: authRepository,
    posRepository: posRepository,
  ));
}

class ComandixApp extends StatelessWidget {
  final AuthRepository authRepository;
  final PosRepository posRepository;

  const ComandixApp({
    super.key,
    required this.authRepository,
    required this.posRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository: authRepository)..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => PosBloc(repository: posRepository),
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
              return const PosMainScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
