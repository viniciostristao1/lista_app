import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/logo_lista.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _entrar() async {
    setState(() => _loading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      // O redirecionamento para o app acontece pelo authStateProvider.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Cancelamento do usuário não é erro.
      if (e.code == 'canceled' || e.code == 'web-context-canceled') return;
      _mostrarErro('firebase_auth/${e.code}', e.message ?? '(sem detalhe)');
    } catch (e) {
      if (!mounted) return;
      _mostrarErro('erro', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _mostrarErro(String codigo, String detalhe) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Não consegui entrar'),
        content: SingleChildScrollView(
          child: SelectableText(
            '$codigo\n\n$detalhe',
            style: const TextStyle(fontSize: 12.5, color: AppColors.dim),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const LogoLista(size: 88),
              const SizedBox(height: 24),
              Text('Lista',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Suas compras de mercado, organizadas\ne comparadas — sem bloco de notas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.dim, height: 1.4),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _entrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.onGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.onGreen),
                        )
                      : const Icon(Icons.login_rounded, size: 20),
                  label: Text(_loading ? 'Entrando…' : 'Entrar com Google'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Seus dados ficam só com você.',
                style: TextStyle(color: AppColors.dim2, fontSize: 12),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
