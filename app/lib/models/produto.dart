import 'package:cloud_firestore/cloud_firestore.dart';

import 'categoria.dart';

/// Item do catálogo pessoal do usuário. Cresce conforme ele cadastra itens;
/// é a fonte das sugestões (autocomplete) e dos preços por mercado.
class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.nomeLower,
    required this.categoria,
    this.ultimoPreco,
    this.ultimoMercadoId,
    this.vezesComprado = 0,
  });

  final String id;
  final String nome;
  final String nomeLower;
  final Categoria categoria;
  final double? ultimoPreco;
  final String? ultimoMercadoId;
  final int vezesComprado;

  factory Produto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Produto(
      id: doc.id,
      nome: (d['nome'] as String?) ?? '',
      nomeLower: (d['nomeLower'] as String?) ?? '',
      categoria: Categoria.fromId(d['categoria'] as String?),
      ultimoPreco: (d['ultimoPreco'] as num?)?.toDouble(),
      ultimoMercadoId: d['ultimoMercadoId'] as String?,
      vezesComprado: (d['vezesComprado'] as num?)?.toInt() ?? 0,
    );
  }
}
