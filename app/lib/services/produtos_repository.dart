import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/categoria.dart';
import '../models/produto.dart';
import 'firestore_refs.dart';

class ProdutosRepository {
  ProdutosRepository(this._refs);

  final FirestoreRefs _refs;

  /// Catálogo inteiro (poucos itens por usuário). Ranqueado por mais comprado.
  Stream<List<Produto>> watchAll() {
    return _refs.produtos.snapshots().map((snap) {
      final lista = snap.docs.map(Produto.fromDoc).toList();
      lista.sort((a, b) => a.nomeLower.compareTo(b.nomeLower)); // ordem alfabética
      return lista;
    });
  }

  /// Cria um produto no catálogo (aba Itens). Retorna o id.
  Future<String> criarProduto({
    required String nome,
    required Categoria categoria,
    String? marca,
    String? tamanho,
    String? unidade,
  }) async {
    final doc = await _refs.produtos.add({
      'nome': nome.trim(),
      'nomeLower': nome.trim().toLowerCase(),
      'categoria': categoria.name,
      'marca': marca,
      'tamanho': tamanho,
      'unidade': unidade,
      'vezesComprado': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    return doc.id;
  }

  /// Atualiza os campos do produto (não mexe nos preços).
  Future<void> atualizarProduto(
    String id, {
    required String nome,
    required Categoria categoria,
    String? marca,
    String? tamanho,
    String? unidade,
  }) {
    return _refs.produtos.doc(id).set({
      'nome': nome.trim(),
      'nomeLower': nome.trim().toLowerCase(),
      'categoria': categoria.name,
      'marca': marca,
      'tamanho': tamanho,
      'unidade': unidade,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<void> excluirProduto(String id) => _refs.produtos.doc(id).delete();

  /// Define/atualiza o preço de um mercado, carimbando a data de hoje, e
  /// guarda no histórico (para a evolução de preço).
  Future<void> definirPreco(
      String produtoId, String mercadoId, double valor) async {
    await _refs.produtos.doc(produtoId).set({
      'precos': {
        mercadoId: {'valor': valor, 'data': Timestamp.now()},
      },
      'ultimoPreco': valor,
      'ultimoMercadoId': mercadoId,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
    await _refs.precos.add({
      'produtoId': produtoId,
      'preco': valor,
      'mercadoId': mercadoId,
      'data': Timestamp.now(),
    });
  }

  /// Remove o preço de um mercado do produto.
  Future<void> removerPreco(String produtoId, String mercadoId) {
    return _refs.produtos
        .doc(produtoId)
        .update({'precos.$mercadoId': FieldValue.delete()});
  }

  /// Ao excluir um mercado, tira o preço dele de todos os produtos.
  Future<void> removerMercadoDeTodos(String mercadoId) async {
    final snap = await _refs.produtos.get();
    final batch = _refs.db.batch();
    var alterou = false;
    for (final doc in snap.docs) {
      final precos = doc.data()['precos'] as Map<String, dynamic>?;
      if (precos != null && precos.containsKey(mercadoId)) {
        batch.update(doc.reference, {'precos.$mercadoId': FieldValue.delete()});
        alterou = true;
      }
    }
    if (alterou) await batch.commit();
  }

  /// Garante que o produto existe (usado ao adicionar item numa lista) e, se
  /// vier preço + mercado, também registra esse preço no catálogo. Retorna o id.
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
    if (preco != null && mercadoId != null) {
      data['precos'] = {
        mercadoId: {'valor': preco, 'data': Timestamp.now()},
      };
    }

    final String id;
    if (existentes.docs.isNotEmpty) {
      id = existentes.docs.first.id;
      await _refs.produtos.doc(id).set(data, SetOptions(merge: true));
    } else {
      data['createdAt'] = Timestamp.now();
      data['vezesComprado'] = 0;
      final doc = await _refs.produtos.add(data);
      id = doc.id;
    }

    if (preco != null && mercadoId != null) {
      await _refs.precos.add({
        'produtoId': id,
        'preco': preco,
        'mercadoId': mercadoId,
        'data': Timestamp.now(),
      });
    }
    return id;
  }
}

final produtosRepoProvider = Provider<ProdutosRepository>((ref) {
  return ProdutosRepository(ref.watch(firestoreRefsProvider));
});

final produtosProvider = StreamProvider<List<Produto>>((ref) {
  return ref.watch(produtosRepoProvider).watchAll();
});
