import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Login com Google via Firebase.
///
/// Usamos `signInWithProvider`, que abre o fluxo do Google numa aba do
/// navegador (Custom Tab). Não exige SHA-1 nem client-ID configurados agora.
/// Trocaremos pelo seletor nativo (google_sign_in) ao preparar o release.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithProvider(provider);
  }

  Future<void> signOut() => _auth.signOut();
}

/// Instância única do serviço de auth.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Estado de login em tempo real (null = deslogado).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authState;
});

/// UID do usuário logado. Só é lido dentro do app (depois do porteiro de auth),
/// onde sempre há usuário.
final uidProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    throw StateError('uidProvider lido sem usuário autenticado');
  }
  return user.uid;
});
