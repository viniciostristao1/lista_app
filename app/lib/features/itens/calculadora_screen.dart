import 'package:flutter/material.dart';

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

class CalculadoraScreen extends StatefulWidget {
  const CalculadoraScreen({super.key});

  @override
  State<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
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
      appBar: AppBar(title: const Text('Calculadora de preço')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
        children: [
          const Text(
            'Compare dois produtos com quantidades (peso/volume) diferentes. '
            'A calculadora diz qual sai mais barato pela mesma quantidade.',
            style: TextStyle(color: AppColors.dim, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          _blocoProduto('Produto A', _precoA, _qtdA),
          const SizedBox(height: 14),
          _blocoProduto('Produto B', _precoB, _qtdB),
          const SizedBox(height: 20),
          if (resultado != null)
            resultado
          else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Preencha preço e quantidade dos dois.',
                  style: TextStyle(color: AppColors.dim2, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _blocoProduto(
      String titulo, TextEditingController preco, TextEditingController qtd) {
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
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _campo(preco, 'Preço', prefix: 'R\$  '),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _campo(qtd, 'Quantidade (g/ml/un)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, {String? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.dim, fontSize: 11.5)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.text, fontSize: 15),
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: const TextStyle(color: AppColors.dim, fontSize: 15),
            hintText: '0',
            hintStyle: const TextStyle(color: AppColors.dim2),
            isDense: true,
            filled: true,
            fillColor: AppColors.bg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.lineStrong),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.lineStrong),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.green),
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
    final vencedor = aMaisBarato ? 'Produto A' : 'Produto B';
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
              const Icon(Icons.emoji_events_outlined,
                  color: AppColors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$vencedor é mais barato (${percent.toStringAsFixed(0)}% mais barato)',
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Com a quantidade do B (${qtdB.toStringAsFixed(qtdB.truncateToDouble() == qtdB ? 0 : 2)}), '
            'o A custaria ${reais(aNoPesoB)}.',
            style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text('O B custa ${reais(precoB)}.',
              style: const TextStyle(color: AppColors.dim, fontSize: 13.5)),
        ],
      ),
    );
  }
}
