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

/// Primeira letra maiúscula, resto intacto: "arroz" -> "Arroz" (útil p/ voz).
String capitalizar(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  return t[0].toUpperCase() + t.substring(1);
}

/// Valor -> texto editável no padrão BR: 18.5 -> "18,50".
String valorEditavel(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

/// Data curta dia/mês (sem ano): 2026-07-05 -> "05/07".
String diaMes(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// Data completa dia/mês/ano: 2026-07-05 -> "05/07/2026".
String dataCompleta(DateTime d) =>
    '${diaMes(d)}/${d.year.toString().padLeft(4, '0')}';

double? parsePreco(String texto) {
  var t = texto.replaceAll(RegExp(r'[^0-9.,]'), '');
  if (t.isEmpty) return null;
  if (t.contains(',')) {
    t = t.replaceAll('.', '').replaceAll(',', '.');
  }
  return double.tryParse(t);
}

String normalizarBusca(String s) {
  final lower = s.toLowerCase();
  const map = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };
  final sb = StringBuffer();
  for (var i = 0; i < lower.length; i++) {
    final c = lower[i];
    sb.write(map[c] ?? c);
  }
  return sb.toString();
}
