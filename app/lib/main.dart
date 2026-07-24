import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ListaApp());
}

class ListaApp extends StatelessWidget {
  const ListaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0E0F13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF33D17F),
          surface: Color(0xFF191C22),
        ),
      ),
      home: const _ConexaoScreen(),
    );
  }
}

/// Tela temporária de fumaça: confirma que o Firebase inicializou.
/// Será substituída pela Fase 1 (Listas / Itens / Pedidos).
class _ConexaoScreen extends StatelessWidget {
  const _ConexaoScreen();

  @override
  Widget build(BuildContext context) {
    final projectId = Firebase.app().options.projectId;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF33D17F), size: 72),
            const SizedBox(height: 20),
            Text('Firebase conectado',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Projeto: $projectId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8B93A1),
                    )),
          ],
        ),
      ),
    );
  }
}
