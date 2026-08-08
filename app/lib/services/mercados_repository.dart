import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mercado.dart';
import 'firestore_refs.dart';

class MercadosRepository {
  MercadosRepository(this._refs);

  final FirestoreRefs _refs;

  Stream<List<Mercado>> watch() {
    return _refs.mercados.snapshots().map((snap) {
      final lista = snap.docs.map(Mercado.fromDoc).toList();
      // ordena pela data de criação (client-side, evita índice composto)
      lista.sort((a, b) => a.id.compareTo(b.id));
      return lista;
    });
  }

  Future<void> criar(
      {required String nome, required Color cor, bool preferencia = false}) {
    return _refs.mercados.add({
      'nome': nome.trim(),
      'cor': cor.toARGB32(),
      'preferencia': preferencia,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> atualizar(String id,
      {required String nome, required Color cor, bool preferencia = false}) {
    return _refs.mercados.doc(id).update({
      'nome': nome.trim(),
      'cor': cor.toARGB32(),
      'preferencia': preferencia,
    });
  }

  Future<void> excluir(String id) => _refs.mercados.doc(id).delete();
}

final mercadosRepoProvider = Provider<MercadosRepository>((ref) {
  return MercadosRepository(ref.watch(firestoreRefsProvider));
});

final mercadosProvider = StreamProvider<List<Mercado>>((ref) {
  return ref.watch(mercadosRepoProvider).watch();
});
