import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Abre a calculadora de comparação por quantidade (pesos diferentes).
Future<void> mostrarCalculadora(BuildContext context) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CalculadoraScreen(),
    ),
  );
}

class CalculadoraScreen extends ConsumerStatefulWidget {
  const CalculadoraScreen({super.key});

  @override
  ConsumerState<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends ConsumerState<CalculadoraScreen> {
  final _precoA = TextEditingController();
  final _qtdA = TextEditingController();
  final _precoB = TextEditingController();
  final _qtdB = TextEditingController();

  @override
  void dispose() {
    _precoA.dispose();
    _qtdA.dispose();
    _precoB.dispose();
    _qtdB.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) => parsePreco(c.text);

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final pA = _num(_precoA), qA = _num(_qtdA);
    final pB = _num(_precoB), qB = _num(_qtdB);

    Widget? resultado;
    if (pA != null && qA != null && qA > 0 && pB != null && qB != null && qB > 0) {
      final unitA = pA / qA;
      final unitB = pB / qB;
      final aNoPesoB = unitA * qB; // A com a quantidade de B
      final aMaisBarato = unitA < unitB;
      final maior = unitA > unitB ? unitA : unitB;
      final menor = unitA < unitB ? unitA : unitB;
      final econPercent = maior > 0 ? (maior - menor) / maior * 100 : 0.0;
      resultado = _resultado(
        aNoPesoB: aNoPesoB,
        precoB: pB,
        qtdB: qB,
        aMaisBarato: aMaisBarato,
        percent: econPercent,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.calculadoraPreco)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          Text(
            t.calculadoraIntro,
            style: TextStyle(color: AppColors.dim, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          _blocoProduto(t.produtoA, _precoA, _qtdA),
          const SizedBox(height: 14),
          _blocoProduto(t.produtoB, _precoB, _qtdB),
          const SizedBox(height: 20),
          if (resultado != null)
            resultado
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.preenchaOsDois,
                  style: TextStyle(color: AppColors.dim2, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _blocoProduto(
      String titulo, TextEditingController preco, TextEditingController qtd) {
    final t = ref.watch(stringsProvider);
    final p = _num(preco), q = _num(qtd);
    final porUnidade = (p != null && q != null && q > 0) ? p / q : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _campo(preco, t.preco, prefix: 'R\$  '),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _campo(qtd, t.quantidade),
              ),
              const SizedBox(width: 10),
              // 3ª coluna: preço por unidade (preço ÷ quantidade), só leitura.
              Expanded(
                child: _resultadoUnidade(porUnidade),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.quantidadeEmUnidades,
              style: TextStyle(color: AppColors.dim2, fontSize: 10.5)),
        ],
      ),
    );
  }

  /// Coluna "Por unidade": resultado (preço ÷ quantidade). Não é campo editável;
  /// tem a mesma altura dos inputs pra alinhar com Preço e Quantidade.
  Widget _resultadoUnidade(double? porUnidade) {
    final t = ref.watch(stringsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.porUnidade,
            style: TextStyle(color: AppColors.dim, fontSize: 11.5)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              porUnidade == null ? '—' : _fmtUnidade(porUnidade),
              style: TextStyle(
                color: porUnidade == null ? AppColors.dim2 : AppColors.green,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Formata o preço por unidade. Pode ser bem pequeno (R$/g, R$/ml) → usa mais
  /// casas quando < 1, sem zeros à toa (mín. 2 casas).
  String _fmtUnidade(double v) {
    if (v >= 1) return reais(v);
    var s = v.toStringAsFixed(4);
    s = s.replaceAll(RegExp(r'0+$'), '');
    final parts = s.split('.');
    if (parts.length == 2 && parts[1].length < 2) {
      s = '${parts[0]}.${parts[1].padRight(2, '0')}';
    }
    return 'R\$ ${s.replaceAll('.', ',')}';
  }

  Widget _campo(TextEditingController c, String label, {String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: AppColors.dim, fontSize: 11.5)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.text, fontSize: 15),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: TextStyle(color: AppColors.dim, fontSize: 15),
            hintText: '0',
            hintStyle: TextStyle(color: AppColors.dim2),
            isDense: true,
            filled: true,
            fillColor: AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.lineStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.lineStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.green),
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultado({
    required double aNoPesoB,
    required double precoB,
    required double qtdB,
    required bool aMaisBarato,
    required double percent,
  }) {
    final t = ref.watch(stringsProvider);
    final vencedor = aMaisBarato ? t.produtoA : t.produtoB;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined,
                  color: AppColors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.vencedorMaisBarato(vencedor, percent.toStringAsFixed(0)),
                  style: TextStyle(
                      color: AppColors.green,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t.comQtdBCustaria(
                qtdB.toStringAsFixed(qtdB.truncateToDouble() == qtdB ? 0 : 2),
                reais(aNoPesoB)),
            style: TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(t.oBCusta(reais(precoB)),
              style: TextStyle(color: AppColors.dim, fontSize: 13.5)),
        ],
      ),
    );
  }
}
