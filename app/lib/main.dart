import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/login_screen.dart';
import 'features/home/home_shell.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/prefs.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: ListaApp()));
}

class ListaApp extends ConsumerWidget {
  const ListaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final escala = ref.watch(fontScaleProvider);
    return MaterialApp(
      title: 'Lista',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // aplica o tamanho de fonte escolhido pelo usuário no app inteiro
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: escala,
        maxScaleFactor: escala,
        child: child!,
      ),
      home: const _AuthGate(),
    );
  }
}

/// Decide a tela pela sessão: deslogado → login; logado → app.
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) => user == null ? const LoginScreen() : const HomeShell(),
      loading: () => const _Splash(),
      error: (_, _) => const _Splash(erro: true),
    );
  }
}

class _Splash extends ConsumerWidget {
  const _Splash({this.erro = false});

  final bool erro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      body: Center(
        child: erro
            ? Text(t.falhaAoCarregar,
                style: const TextStyle(color: AppColors.dim))
            : const CircularProgressIndicator(color: AppColors.green),
      ),
    );
  }
}
