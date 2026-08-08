import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Um mercado favorito do usuário (até 3). Cor usada na legenda e nos badges.
class Mercado {
  const Mercado({
    required this.id,
    required this.nome,
    required this.cor,
    this.preferencia = false,
  });

  final String id;
  final String nome;
  final Color cor;

  /// Mercado "preferência": itens sem preço vão pra ele (além de "Todos").
  /// Só um mercado pode ser preferência por vez.
  final bool preferencia;

  factory Mercado.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Mercado(
      id: doc.id,
      nome: (d['nome'] as String?) ?? 'Mercado',
      cor: Color((d['cor'] as int?) ?? 0xFF33D17F),
      preferencia: (d['preferencia'] as bool?) ?? false,
    );
  }
}
