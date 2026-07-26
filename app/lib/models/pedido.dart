import 'package:cloud_firestore/cloud_firestore.dart';

import 'categoria.dart';

/// Um item congelado dentro de um pedido (para exibir e para "desfazer").
class PedidoItem {
  const PedidoItem({
    this.produtoId,
    required this.nome,
    required this.categoria,
    this.quantidade = 1,
    this.precoUnit,
  });

  final String? produtoId;
  final String nome;
  final Categoria categoria;
  final int quantidade;
  final double? precoUnit;

  double get subtotal => (precoUnit ?? 0) * quantidade;

  Map<String, dynamic> toMap() => {
        'produtoId': produtoId,
        'nome': nome,
        'categoria': categoria.name,
        'quantidade': quantidade,
        'precoUnit': precoUnit,
      };

  factory PedidoItem.fromMap(Map<String, dynamic> m) => PedidoItem(
        produtoId: m['produtoId'] as String?,
        nome: (m['nome'] as String?) ?? '',
        categoria: Categoria.fromId(m['categoria'] as String?),
        quantidade: (m['quantidade'] as num?)?.toInt() ?? 1,
        precoUnit: (m['precoUnit'] as num?)?.toDouble(),
      );
}

/// Uma compra finalizada (histórico). Guarda data, mercado, total, economia e
/// o retrato dos itens (para desfazer, devolvendo à lista).
class Pedido {
  const Pedido({
    required this.id,
    this.data,
    this.mercadoId,
    this.total = 0,
    this.economia = 0,
    this.itens = const [],
  });

  final String id;
  final DateTime? data;
  final String? mercadoId; // null = "Todos" (vários mercados)
  final double total;
  final double economia;
  final List<PedidoItem> itens;

  factory Pedido.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final rawItens = (d['itens'] as List?) ?? const [];
    return Pedido(
      id: doc.id,
      data: (d['data'] as Timestamp?)?.toDate(),
      mercadoId: d['mercadoId'] as String?,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      economia: (d['economia'] as num?)?.toDouble() ?? 0,
      itens: rawItens
          .map((e) => PedidoItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
