import 'package:cloud_firestore/cloud_firestore.dart';

/// Uma lista de compras. `ativa` enquanto o usuário compra; `finalizada` vira
/// um "pedido" no histórico.
class Lista {
  const Lista({
    required this.id,
    required this.nome,
    required this.status,
    this.createdAt,
    this.finalizadaAt,
    this.mercadoPredominanteId,
    this.totalGasto = 0,
    this.qtdItens = 0,
  });

  final String id;
  final String nome;
  final String status; // 'ativa' | 'finalizada'
  final DateTime? createdAt;
  final DateTime? finalizadaAt;
  final String? mercadoPredominanteId;
  final double totalGasto;
  final int qtdItens;

  bool get ativa => status == 'ativa';

  factory Lista.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Lista(
      id: doc.id,
      nome: (d['nome'] as String?) ?? 'Lista',
      status: (d['status'] as String?) ?? 'ativa',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      finalizadaAt: (d['finalizadaAt'] as Timestamp?)?.toDate(),
      mercadoPredominanteId: d['mercadoPredominanteId'] as String?,
      totalGasto: (d['totalGasto'] as num?)?.toDouble() ?? 0,
      qtdItens: (d['qtdItens'] as num?)?.toInt() ?? 0,
    );
  }
}
