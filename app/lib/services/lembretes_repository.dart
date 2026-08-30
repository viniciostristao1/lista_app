import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lembrete.dart';
import 'firestore_refs.dart';

class LembretesRepository {
  LembretesRepository(this._refs);
  final FirestoreRefs _refs;

  CollectionReference<Map<String, dynamic>> get _col =>
      _refs.db.collection('users').doc(_refs.uid).collection('lembretes');

  Stream<List<Lembrete>> watch() {
    return _col.orderBy('dataHora').snapshots().map((snap) => snap.docs.map(Lembrete.fromDoc).toList());
  }

  Future<String> criar(Lembrete l) async {
    final doc = await _col.add(l.toMap());
    return doc.id;
  }

  Future<void> atualizar(String id, Map<String, dynamic> dados) => _col.doc(id).update(dados);

  Future<void> salvar(Lembrete l) => _col.doc(l.id).set(l.toMap(), SetOptions(merge: true));

  Future<void> excluir(String id) => _col.doc(id).delete();

  Future<void> toggleAtivo(String id, bool ativo) => _col.doc(id).update({'ativo': ativo});
}

final lembretesRepoProvider = Provider<LembretesRepository>((ref) {
  return LembretesRepository(ref.watch(firestoreRefsProvider));
});

final lembretesProvider = StreamProvider<List<Lembrete>>((ref) {
  return ref.watch(lembretesRepoProvider).watch();
});
