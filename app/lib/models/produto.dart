import 'package:cloud_firestore/cloud_firestore.dart';

import 'categoria.dart';

/// Preço de um produto num mercado específico, com a data do cadastro.
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
    this.observacoes,
    this.observacoesAtualizadasEm,
    this.updatedAt,
    this.fixado = false,
    this.mercadoFixo,
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
  final String? observacoes;

  /// Quando as [observacoes] foram escritas/atualizadas pela última vez.
  final DateTime? observacoesAtualizadasEm;

  /// Última modificação de qualquer campo (fallback p/ a data de observações
  /// de produtos antigos, criados antes de existir [observacoesAtualizadasEm]).
  final DateTime? updatedAt;

  /// Fixado = "recorrente": não sai da lista ao "Finalizar compra" (só por
  /// exclusão manual). No modelo atual, recorrente sempre tem [mercadoFixo].
  final bool fixado;

  /// Se definido, o item é "de um mercado só" (dedicado): não se compara preço
  /// entre mercados — ele vive no mercado [mercadoFixo]. Null = item comparável.
  final String? mercadoFixo;

  final double? ultimoPreco;
  final String? ultimoMercadoId;
  final int vezesComprado;

  /// mercadoId -> preço naquele mercado.
  final Map<String, PrecoMercado> precos;

  /// Item "de um mercado só" — sem comparação de preço.
  bool get dedicado => mercadoFixo != null;

  /// "Pilão · 500g" — só o que existir.
  String get detalhe {
    final partes = <String>[];
    if (marca != null && marca!.trim().isNotEmpty) partes.add(marca!.trim());
    final tam = '${tamanho?.trim() ?? ''}${unidade?.trim() ?? ''}';
    if (tam.isNotEmpty) partes.add(tam);
    return partes.join(' · ');
  }

  /// Preços ordenados do menor pro maior. **Vazio** quando o item é dedicado
  /// (mercado fixo) — aí não há o que comparar e o preço "some" da UI/cálculos.
  List<MapEntry<String, PrecoMercado>> get precosOrdenados {
    if (dedicado) return const [];
    final l = precos.entries.toList();
    l.sort((a, b) => a.value.valor.compareTo(b.value.valor));
    return l;
  }

  double? get menorPreco =>
      precosOrdenados.isEmpty ? null : precosOrdenados.first.value.valor;
  String? get mercadoMaisBarato =>
      precosOrdenados.isEmpty ? null : precosOrdenados.first.key;
  double? get segundoMenorPreco =>
      precosOrdenados.length >= 2 ? precosOrdenados[1].value.valor : null;

  /// Economia do menor para o 2º menor preço (0 se houver menos de 2 mercados).
  double get economia {
    final menor = menorPreco;
    final segundo = segundoMenorPreco;
    if (menor == null || segundo == null) return 0;
    return segundo - menor;
  }

  /// Data da atualização de preço mais recente (para exibir dia/mês no card).
  DateTime? get ultimaAtualizacao {
    final ord = precosOrdenados;
    if (ord.isEmpty) return null;
    return ord.map((e) => e.value.data).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Data da última observação gravada. Produtos antigos (sem a marca) caem
  /// no [updatedAt] para não ficarem sem data.
  DateTime? get observacoesData => observacoesAtualizadasEm ?? updatedAt;

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
      observacoes: d['observacoes'] as String?,
      observacoesAtualizadasEm:
          (d['observacoesAtualizadasEm'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      fixado: (d['fixado'] as bool?) ?? false,
      mercadoFixo: d['mercadoFixo'] as String?,
      ultimoPreco: (d['ultimoPreco'] as num?)?.toDouble(),
      ultimoMercadoId: d['ultimoMercadoId'] as String?,
      vezesComprado: (d['vezesComprado'] as num?)?.toInt() ?? 0,
      precos: precos,
    );
  }
}
