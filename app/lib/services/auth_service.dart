import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Login com Google **nativo** (google_sign_in), o seletor de conta do Android.
/// Substitui o antigo `signInWithProvider` (fluxo por navegador), que dava
/// erro de "Generic IDP flow". Usa o Web client ID como serverClientId.
///
/// O Web client ID não é segredo (é público/derivável, vai no app de qualquer forma).
const _serverClientId =
    '585404124028-bjfserst10uguolpuna3sk6ju5h17rg8.apps.googleusercontent.com';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  bool _gsiInit = false;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInit() async {
    if (_gsiInit) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _gsiInit = true;
  }

  Future<void> signInWithGoogle() async {
    await _ensureInit();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignora se o google_sign_in ainda não foi inicializado
    }
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Estado de login em tempo real (null = deslogado).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authState;
});

/// UID do usuário logado. Só é lido dentro do app (depois do porteiro de auth).
final uidProvider = Provider<String>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) {
    throw StateError('uidProvider lido sem usuário autenticado');
  }
  return user.uid;
});
