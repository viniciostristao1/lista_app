/// Formata um valor em Reais no padrão brasileiro: 1234.5 -> "R$ 1.234,50".
String reais(double v) {
  final fixed = v.toStringAsFixed(2);
  final parts = fixed.split('.');
  final inteiro = parts[0];
  final centavos = parts[1];

  final buf = StringBuffer();
  final neg = inteiro.startsWith('-');
  final digits = neg ? inteiro.substring(1) : inteiro;
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }
  return 'R\$ ${neg ? '-' : ''}${buf.toString()},$centavos';
}

/// "hoje" / "ontem" / "há N dias" a partir de uma quantidade de dias.
String haDias(int dias) {
  if (dias <= 0) return 'hoje';
  if (dias == 1) return 'ontem';
  return 'há $dias dias';
}

/// Valor -> texto editável no padrão BR: 18.5 -> "18,50".
String valorEditavel(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

/// Lê um preço digitado ("18,50", "1.234,56", "18.5") -> double? (null se vazio).
double? parsePreco(String texto) {
  var t = texto.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    // vírgula = decimal; pontos = milhares
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}
