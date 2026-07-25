import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../models/item_lista.dart';
import '../models/lista.dart';
import 'firestore_refs.dart';

class ListasRepository {
  ListasRepository(this._refs);

  final FirestoreRefs _refs;

  Stream<List<Lista>> _watchPorStatus(String status) {
    return _refs.listas.where('status', isEqualTo: status).snapshots().map(
      (snap) {
        final lista = snap.docs.map(Lista.fromDoc).toList();
        lista.sort((a, b) {
          final da = a.finalizadaAt ?? a.createdAt;
          final db = b.finalizadaAt ?? b.createdAt;
          if (da == null || db == null) return 0;
          return db.compareTo(da); // mais recentes primeiro
        });
        return lista;
      },
    );
  }

  Stream<List<Lista>> watchAtivas() => _watchPorStatus('ativa');
  Stream<List<Lista>> watchFinalizadas() => _watchPorStatus('finalizada');

  Future<String> criar(String nome) async {
    final doc = await _refs.listas.add({
      'nome': nome.trim(),
      'status': 'ativa',
      'createdAt': Timestamp.now(),
      'totalGasto': 0,
      'qtdItens': 0,
    });
    return doc.id;
  }

  Future<void> renomear(String id, String nome) =>
      _refs.listas.doc(id).update({'nome': nome.trim()});

  Future<void> excluir(String id) async {
    final itens = await _refs.itens(id).get();
    final batch = _refs.db.batch();
    for (final d in itens.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_refs.listas.doc(id));
    await batch.commit();
  }

  // ---- itens ----

  Stream<List<ItemLista>> watchItens(String listaId) {
    return _refs.itens(listaId).snapshots().map((snap) {
      final itens = snap.docs.map(ItemLista.fromDoc).toList();
      return itens;
    });
  }

  Future<void> adicionarItem(
    String listaId, {
    String? produtoId,
    required String nome,
    required Categoria categoria,
    int quantidade = 1,
    double? preco,
    String? mercadoId,
  }) {
    return _refs.itens(listaId).add({
      'produtoId': produtoId,
      'nome': nome.trim(),
      'categoria': categoria.name,
      'quantidade': quantidade,
      'preco': preco,
      'mercadoId': mercadoId,
      'comprado': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> setComprado(String listaId, String itemId, bool comprado) =>
      _refs.itens(listaId).doc(itemId).update({'comprado': comprado});

  Future<void> removerItem(String listaId, String itemId) =>
      _refs.itens(listaId).doc(itemId).delete();

  /// Remove vários itens de uma vez (usado ao finalizar a compra de um mercado).
  Future<void> removerItens(String listaId, List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _refs.db.batch();
    for (final id in ids) {
      batch.delete(_refs.itens(listaId).doc(id));
    }
    await batch.commit();
  }

  /// Retorna a lista de compras atual (a única ativa). Cria uma se não existir.
  Future<Lista> obterOuCriarAtiva() async {
    final snap = await _refs.listas.where('status', isEqualTo: 'ativa').get();
    if (snap.docs.isNotEmpty) {
      final ativas = snap.docs.map(Lista.fromDoc).toList();
      ativas.sort((a, b) {
        final da = a.createdAt;
        final db = b.createdAt;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
      return ativas.first;
    }
    final id = await criar('Minha lista');
    return Lista(id: id, nome: 'Minha lista', status: 'ativa');
  }

  /// Fecha a compra atual (vira histórico). Guarda um total estimado.
  Future<void> finalizarSimples(
    String listaId, {
    required double total,
    required int qtdItens,
  }) {
    return _refs.listas.doc(listaId).update({
      'status': 'finalizada',
      'finalizadaAt': Timestamp.now(),
      'totalGasto': total,
      'qtdItens': qtdItens,
    });
  }

  /// Finaliza a lista: vira "pedido". Congela total/qtd/mercado predominante,
  /// grava observações de preço e conta +1 em cada produto comprado.
  Future<void> finalizar(String listaId, List<ItemLista> itens) async {
    final comprados = itens.where((e) => e.comprado).toList();

    double total = 0;
    final contagemMercado = <String, int>{};
    for (final it in comprados) {
      total += it.subtotal;
      final m = it.mercadoId;
      if (m != null) contagemMercado[m] = (contagemMercado[m] ?? 0) + 1;
    }
    String? predominante;
    var melhor = -1;
    contagemMercado.forEach((mercado, n) {
      if (n > melhor) {
        melhor = n;
        predominante = mercado;
      }
    });

    final batch = _refs.db.batch();
    batch.update(_refs.listas.doc(listaId), {
      'status': 'finalizada',
      'finalizadaAt': Timestamp.now(),
      'totalGasto': total,
      'qtdItens': comprados.length,
      'mercadoPredominanteId': predominante,
    });

    for (final it in comprados) {
      if (it.preco == null) continue;
      batch.set(_refs.precos.doc(), {
        'produtoId': it.produtoId,
        'nome': it.nome,
        'preco': it.preco,
        'mercadoId': it.mercadoId,
        'data': Timestamp.now(),
        'listaId': listaId,
      });
      if (it.produtoId != null) {
        batch.set(
          _refs.produtos.doc(it.produtoId!),
          {'vezesComprado': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    }

    await batch.commit();
  }
}

final listasRepoProvider = Provider<ListasRepository>((ref) {
  return ListasRepository(ref.watch(firestoreRefsProvider));
});

final listasAtivasProvider = StreamProvider<List<Lista>>((ref) {
  return ref.watch(listasRepoProvider).watchAtivas();
});

final itensProvider =
    StreamProvider.family<List<ItemLista>, String>((ref, listaId) {
  return ref.watch(listasRepoProvider).watchItens(listaId);
});
