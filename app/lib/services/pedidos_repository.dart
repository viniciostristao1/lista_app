import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pedido.dart';
import 'firestore_refs.dart';

class PedidosRepository {
  PedidosRepository(this._refs);

  final FirestoreRefs _refs;

  Stream<List<Pedido>> watchAll() {
    return _refs.pedidos.snapshots().map((snap) {
      final l = snap.docs.map(Pedido.fromDoc).toList();
      l.sort((a, b) {
        final da = a.data, db = b.data;
        if (da == null || db == null) return 0;
        return db.compareTo(da); // mais recentes primeiro
      });
      return l;
    });
  }

  Future<void> criar({
    String? mercadoId,
    required double total,
    required double economia,
    required List<PedidoItem> itens,
  }) {
    return _refs.pedidos.add({
      'data': Timestamp.now(),
      'mercadoId': mercadoId,
      'total': total,
      'economia': economia,
      'itens': itens.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> excluir(String id) => _refs.pedidos.doc(id).delete();
}

final pedidosRepoProvider = Provider<PedidosRepository>((ref) {
  return PedidosRepository(ref.watch(firestoreRefsProvider));
});

final pedidosProvider = StreamProvider<List<Pedido>>((ref) {
  return ref.watch(pedidosRepoProvider).watchAll();
});
