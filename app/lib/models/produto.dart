import 'package:cloud_firestore/cloud_firestore.dart';

import 'categoria.dart';

/// Preço de um produto num mercado específico, com a data do cadastro.
/// A data alimenta o alerta de "preço desatualizado".
class PrecoMercado {
  const PrecoMercado({required this.valor, required this.data});

  final double valor;
  final DateTime data;

  int get diasDesde => DateTime.now().difference(data).inDays;

  /// Acima de 30 dias o preço não é confiável.
  bool get desatualizado => diasDesde > 30;
}

/// Item do catálogo pessoal. Guarda os campos do produto e o preço em cada
/// mercado (com data). É a fonte das sugestões e do comparador.
class Produto {
  const Produto({
    required this.id,
    required this.nome,
    required this.nomeLower,
    required this.categoria,
    this.marca,
    this.tamanho,
    this.unidade,
    this.ultimoPreco,
    this.ultimoMercadoId,
    this.vezesComprado = 0,
    this.precos = const {},
  });

  final String id;
  final String nome;
  final String nomeLower;
  final Categoria categoria;
  final String? marca;
  final String? tamanho;
  final String? unidade;
  final double? ultimoPreco;
  final String? ultimoMercadoId;
  final int vezesComprado;

  /// mercadoId -> preço naquele mercado.
  final Map<String, PrecoMercado> precos;

  /// "Pilão · 500g" — só o que existir.
  String get detalhe {
    final partes = <String>[];
    if (marca != null && marca!.trim().isNotEmpty) partes.add(marca!.trim());
    final tam = '${tamanho?.trim() ?? ''}${unidade?.trim() ?? ''}';
    if (tam.isNotEmpty) partes.add(tam);
    return partes.join(' · ');
  }

  List<MapEntry<String, PrecoMercado>> get precosOrdenados {
    final l = precos.entries.toList();
    l.sort((a, b) => a.value.valor.compareTo(b.value.valor));
    return l;
  }

  double? get menorPreco =>
      precos.isEmpty ? null : precosOrdenados.first.value.valor;
  String? get mercadoMaisBarato =>
      precos.isEmpty ? null : precosOrdenados.first.key;
  double? get segundoMenorPreco =>
      precos.length >= 2 ? precosOrdenados[1].value.valor : null;

  /// Economia do menor para o 2º menor preço (0 se houver menos de 2 mercados).
  double get economia {
    final menor = menorPreco;
    final segundo = segundoMenorPreco;
    if (menor == null || segundo == null) return 0;
    return segundo - menor;
  }

  factory Produto.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final precosRaw = (d['precos'] as Map<String, dynamic>?) ?? const {};
    final precos = <String, PrecoMercado>{};
    precosRaw.forEach((mercadoId, v) {
      final m = v as Map<String, dynamic>?;
      final valor = (m?['valor'] as num?)?.toDouble();
      final data = (m?['data'] as Timestamp?)?.toDate();
      if (valor != null && data != null) {
        precos[mercadoId] = PrecoMercado(valor: valor, data: data);
      }
    });
    return Produto(
      id: doc.id,
      nome: (d['nome'] as String?) ?? '',
      nomeLower: (d['nomeLower'] as String?) ?? '',
      categoria: Categoria.fromId(d['categoria'] as String?),
      marca: d['marca'] as String?,
      tamanho: d['tamanho'] as String?,
      unidade: d['unidade'] as String?,
      ultimoPreco: (d['ultimoPreco'] as num?)?.toDouble(),
      ultimoMercadoId: d['ultimoMercadoId'] as String?,
      vezesComprado: (d['vezesComprado'] as num?)?.toInt() ?? 0,
      precos: precos,
    );
  }
}
