import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_service.dart';

/// Atalhos para as coleções do usuário. Tudo mora sob `users/{uid}/...`,
/// o que combina com a regra de segurança (só o dono acessa).
class FirestoreRefs {
  FirestoreRefs(this.db, this.uid);

  final FirebaseFirestore db;
  final String uid;

  DocumentReference<Map<String, dynamic>> get _user =>
      db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get mercados =>
      _user.collection('mercados');
  CollectionReference<Map<String, dynamic>> get produtos =>
      _user.collection('produtos');
  CollectionReference<Map<String, dynamic>> get listas =>
      _user.collection('listas');
  CollectionReference<Map<String, dynamic>> itens(String listaId) =>
      listas.doc(listaId).collection('itens');
  CollectionReference<Map<String, dynamic>> get precos =>
      _user.collection('precos');
  CollectionReference<Map<String, dynamic>> get pedidos =>
      _user.collection('pedidos');
}

final firestoreRefsProvider = Provider<FirestoreRefs>((ref) {
  final uid = ref.watch(uidProvider);
  return FirestoreRefs(FirebaseFirestore.instance, uid);
});
