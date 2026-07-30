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
    String? observacoes,
    bool fixado = false,
    String? mercadoFixo,
  }) async {
    final doc = await _refs.produtos.add({
      'nome': nome.trim(),
      'nomeLower': nome.trim().toLowerCase(),
      'categoria': categoria.name,
      'marca': marca,
      'tamanho': tamanho,
      'unidade': unidade,
      'observacoes': observacoes,
      'fixado': fixado,
      'mercadoFixo': mercadoFixo,
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
    String? observacoes,
    bool fixado = false,
    String? mercadoFixo,
  }) {
    return _refs.produtos.doc(id).set({
      'nome': nome.trim(),
      'nomeLower': nome.trim().toLowerCase(),
      'categoria': categoria.name,
      'marca': marca,
      'tamanho': tamanho,
      'unidade': unidade,
      'observacoes': observacoes,
      'fixado': fixado,
      'mercadoFixo': mercadoFixo,
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

  /// Ao excluir um mercado, tira o preço dele de todos os produtos e desfaz
  /// qualquer "mercado fixo" (dedicado/recorrente) que apontava pra ele.
  Future<void> removerMercadoDeTodos(String mercadoId) async {
    final snap = await _refs.produtos.get();
    final batch = _refs.db.batch();
    var alterou = false;
    for (final doc in snap.docs) {
      final data = doc.data();
      final updates = <String, dynamic>{};
      final precos = data['precos'] as Map<String, dynamic>?;
      if (precos != null && precos.containsKey(mercadoId)) {
        updates['precos.$mercadoId'] = FieldValue.delete();
      }
      if (data['mercadoFixo'] == mercadoId) {
        updates['mercadoFixo'] = FieldValue.delete();
        updates['fixado'] = false; // recorrente exige um mercado
      }
      if (updates.isNotEmpty) {
        batch.update(doc.reference, updates);
        alterou = true;
      }
    }
    if (alterou) await batch.commit();
  }

  /// Higieniza o catálogo: remove de todos os produtos os preços de mercados
  /// que não existem mais (órfãos de exclusões antigas ou incompletas) e zera
  /// o "último mercado" se ele apontar para um mercado excluído.
  ///
  /// Segurança: NUNCA chamar com [mercadosValidos] vazio — isso apagaria todos
  /// os preços. Retorna quantos produtos foram alterados (0 = nada a limpar).
  Future<int> limparPrecosOrfaos(Set<String> mercadosValidos) async {
    if (mercadosValidos.isEmpty) return 0;
    final snap = await _refs.produtos.get();
    final batch = _refs.db.batch();
    var tocados = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final precos = data['precos'] as Map<String, dynamic>?;
      final orfaos = precos == null
          ? const <String>[]
          : precos.keys.where((id) => !mercadosValidos.contains(id)).toList();
      final ultimoMerc = data['ultimoMercadoId'] as String?;
      final ultimoOrfao =
          ultimoMerc != null && !mercadosValidos.contains(ultimoMerc);
      final mercadoFixo = data['mercadoFixo'] as String?;
      final fixoOrfao =
          mercadoFixo != null && !mercadosValidos.contains(mercadoFixo);
      if (orfaos.isEmpty && !ultimoOrfao && !fixoOrfao) continue;

      final updates = <String, dynamic>{};
      for (final id in orfaos) {
        updates['precos.$id'] = FieldValue.delete();
      }
      if (ultimoOrfao) {
        updates['ultimoMercadoId'] = FieldValue.delete();
        updates['ultimoPreco'] = FieldValue.delete();
      }
      if (fixoOrfao) {
        updates['mercadoFixo'] = FieldValue.delete();
        updates['fixado'] = false; // recorrente exige um mercado
      }
      batch.update(doc.reference, updates);
      tocados++;
    }
    if (tocados > 0) await batch.commit();
    return tocados;
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
