import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mercado.dart';
import '../util/format.dart';
import 'firestore_refs.dart';
import 'prefs.dart';

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

  Future<String> criar(
      {required String nome, required Color cor, bool preferencia = false}) async {
    final doc = await _refs.mercados.add({
      'nome': capitalizar(nome),
      'cor': cor.toARGB32(),
      'preferencia': preferencia,
      'createdAt': Timestamp.now(),
    });
    return doc.id;
  }

  Future<void> atualizar(String id,
      {required String nome, required Color cor, bool preferencia = false}) {
    return _refs.mercados.doc(id).update({
      'nome': capitalizar(nome),
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

/// Tokens da ordem manual que não são mercados: a posição de "Todos" e de
/// "Sem mercado" na prateleira (também arrastáveis no editor de mercados).
const tokenTodos = '__todos__';
const tokenSemMercado = '__sem__';

/// Aplica a ordem manual do usuário: mercados na sequência salva (tokens de
/// "Todos"/"Sem mercado" são ignorados); o que não estiver na lista vai pro
/// fim, na ordem original.
List<Mercado> mercadosNaOrdem(List<Mercado> mercados, List<String> ordem) {
  final porId = {for (final m in mercados) m.id: m};
  final resultado = <Mercado>[];
  final vistos = <String>{};
  for (final token in ordem) {
    final m = porId[token];
    if (m != null && vistos.add(token)) resultado.add(m);
  }
  for (final m in mercados) {
    if (vistos.add(m.id)) resultado.add(m);
  }
  return resultado;
}

/// Mercados já na ordem que deve aparecer nas telas: automático = ordem do
/// provider (como sempre foi); manual = ordem arrumada pelo usuário.
final mercadosOrdenadosProvider = Provider<List<Mercado>>((ref) {
  final mercados =
      ref.watch(mercadosProvider).asData?.value ?? const <Mercado>[];
  if (ref.watch(mercadosAutoProvider)) return mercados;
  return mercadosNaOrdem(mercados, ref.watch(mercadosOrdemProvider));
});
