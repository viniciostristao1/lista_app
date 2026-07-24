import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../models/produto.dart';
import 'firestore_refs.dart';

class ProdutosRepository {
  ProdutosRepository(this._refs);

  final FirestoreRefs _refs;

  /// Catálogo inteiro (poucos itens por usuário). Usado para sugestões e para a
  /// aba Itens. Ranqueado por mais comprado.
  Stream<List<Produto>> watchAll() {
    return _refs.produtos.snapshots().map((snap) {
      final lista = snap.docs.map(Produto.fromDoc).toList();
      lista.sort((a, b) {
        final c = b.vezesComprado.compareTo(a.vezesComprado);
        return c != 0 ? c : a.nomeLower.compareTo(b.nomeLower);
      });
      return lista;
    });
  }

  /// Garante que o produto existe no catálogo e atualiza último preço/mercado.
  /// Retorna o id do produto (para vincular ao item da lista).
  Future<String> registrar({
    required String nome,
    required Categoria categoria,
    double? preco,
    String? mercadoId,
  }) async {
    final nomeLower = nome.trim().toLowerCase();
    final existentes = await _refs.produtos
        .where('nomeLower', isEqualTo: nomeLower)
        .limit(1)
        .get();

    final data = <String, dynamic>{
      'nome': nome.trim(),
      'nomeLower': nomeLower,
      'categoria': categoria.name,
      'ultimoPreco': ?preco,
      'ultimoMercadoId': ?mercadoId,
      'updatedAt': Timestamp.now(),
    };

    if (existentes.docs.isNotEmpty) {
      final id = existentes.docs.first.id;
      await _refs.produtos.doc(id).set(data, SetOptions(merge: true));
      return id;
    }
    data['createdAt'] = Timestamp.now();
    data['vezesComprado'] = 0;
    final doc = await _refs.produtos.add(data);
    return doc.id;
  }
}

final produtosRepoProvider = Provider<ProdutosRepository>((ref) {
  return ProdutosRepository(ref.watch(firestoreRefsProvider));
});

final produtosProvider = StreamProvider<List<Produto>>((ref) {
  return ref.watch(produtosRepoProvider).watchAll();
});
