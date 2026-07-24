import 'package:cloud_firestore/cloud_firestore.dart';

import 'categoria.dart';

/// Um item dentro de uma lista. Guarda um "retrato" do nome/categoria para ser
/// robusto caso o produto do catálogo seja renomeado depois.
class ItemLista {
  const ItemLista({
    required this.id,
    this.produtoId,
    required this.nome,
    required this.categoria,
    this.quantidade = 1,
    this.preco,
    this.mercadoId,
    this.comprado = false,
  });

  final String id;
  final String? produtoId;
  final String nome;
  final Categoria categoria;
  final int quantidade;
  final double? preco;
  final String? mercadoId;
  final bool comprado;

  /// Quanto esse item soma no total (preço × quantidade), 0 se sem preço.
  double get subtotal => (preco ?? 0) * quantidade;

  factory ItemLista.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return ItemLista(
      id: doc.id,
      produtoId: d['produtoId'] as String?,
      nome: (d['nome'] as String?) ?? '',
      categoria: Categoria.fromId(d['categoria'] as String?),
      quantidade: (d['quantidade'] as num?)?.toInt() ?? 1,
      preco: (d['preco'] as num?)?.toDouble(),
      mercadoId: d['mercadoId'] as String?,
      comprado: (d['comprado'] as bool?) ?? false,
    );
  }
}
