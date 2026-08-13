import 'package:flutter/material.dart';

/// Um tema = um conjunto completo de cores (uma [Palette]). O app troca a
/// paleta ativa em tempo real (ver `AppColors.palette` + `temaProvider`).
class Palette {
  const Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.dim,
    required this.dim2,
    required this.green,
    required this.onGreen,
    required this.blue,
    required this.amber,
    required this.danger,
    required this.cardGrad1,
    required this.cardGrad2,
    required this.navBg,
    this.navAccent = false,
  });

  final Brightness brightness;
  final Color bg; // fundo
  final Color surface; // cards
  final Color surface2; // hover / elevação
  final Color line; // borda de card (transparente no estilo Flat)
  final Color lineStrong; // arestas estruturais (stepper/inputs/divisórias)
  final Color text; // texto principal
  final Color dim; // texto secundário
  final Color dim2; // texto terciário / ícones apagados
  final Color green; // ACENTO do app (mantém o nome por compatibilidade)
  final Color onGreen; // texto sobre o acento
  final Color blue; // ações
  final Color amber;
  final Color danger;
  final Color cardGrad1; // gradiente dos cards de destaque (economia/resumo)
  final Color cardGrad2;
  final Color navBg; // fundo da barra de navegação inferior
  // Se true, a barra inferior usa o ACENTO como fundo (com texto onGreen), pra
  // dar contraste. Se false, usa navBg (fundo neutro) com o acento no item ativo.
  final bool navAccent;
}

/// Os temas disponíveis (escolha do usuário em Configurações).
enum Tema { ambar, begeAreia, claroAzul, ameixa }

/// Âmbar escuro — o tema original do app (padrão).
const _ambar = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF0E0F13),
  surface: Color(0xFF191C22),
  surface2: Color(0xFF212530),
  line: Color(0x00FFFFFF),
  lineStrong: Color(0x14FFFFFF),
  text: Color(0xFFEDEFF3),
  dim: Color(0xFF8B93A1),
  dim2: Color(0xFF5F6674),
  green: Color(0xFFE0A24A),
  onGreen: Color(0xFF201603),
  blue: Color(0xFF4C8DFF),
  amber: Color(0xFFF2B84B),
  danger: Color(0xFFFF7A7A),
  cardGrad1: Color(0xFF1D2128),
  cardGrad2: Color(0xFF171A20),
  navBg: Color(0xFF101216),
);

/// Bege Areia — claro, creme quente com acento marrom (no lugar do âmbar).
const _begeAreia = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF1EADC),
  surface: Color(0xFFFBF7EE),
  surface2: Color(0xFFF2EADA),
  line: Color(0x00000000),
  lineStrong: Color(0x14000000),
  text: Color(0xFF3A322A),
  dim: Color(0xFF877A67),
  dim2: Color(0xFFA99B85),
  green: Color(0xFF8A5A3B),
  onGreen: Color(0xFFFBF3E8),
  blue: Color(0xFF3A6F9E),
  amber: Color(0xFFB5723A),
  danger: Color(0xFFB0442F),
  cardGrad1: Color(0xFFF8F1E3),
  cardGrad2: Color(0xFFF1E7D6),
  navBg: Color(0xFFEDE3D1),
  navAccent: true, // barra inferior marrom
);

/// Claro Azul — tema claro, cartões brancos e acento azul.
const _claroAzul = Palette(
  brightness: Brightness.light,
  bg: Color(0xFFF3F5FA),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFEDF1F8),
  line: Color(0x00000000),
  lineStrong: Color(0x14000000),
  text: Color(0xFF1B2430),
  dim: Color(0xFF66717F),
  dim2: Color(0xFF98A2B0),
  green: Color(0xFF2F6BE0),
  onGreen: Color(0xFFFFFFFF),
  blue: Color(0xFF2F6BE0),
  amber: Color(0xFFC5851F),
  danger: Color(0xFFD64545),
  cardGrad1: Color(0xFFFFFFFF),
  cardGrad2: Color(0xFFF0F4FC),
  navBg: Color(0xFFFFFFFF),
  navAccent: true, // barra inferior azul
);

/// Ameixa — escuro, violeta suave.
const _ameixa = Palette(
  brightness: Brightness.dark,
  bg: Color(0xFF16121C),
  surface: Color(0xFF221A2A),
  surface2: Color(0xFF2C2235),
  line: Color(0x00FFFFFF),
  lineStrong: Color(0x18FFFFFF),
  text: Color(0xFFEEE7F2),
  dim: Color(0xFF9D8FA8),
  dim2: Color(0xFF6E6280),
  green: Color(0xFFB98AD9),
  onGreen: Color(0xFF1B0F27),
  blue: Color(0xFF7CC0F0),
  amber: Color(0xFFE0A24A),
  danger: Color(0xFFFF7A9A),
  cardGrad1: Color(0xFF241C2D),
  cardGrad2: Color(0xFF1C1622),
  navBg: Color(0xFF120E18),
  navAccent: true, // barra inferior ameixa
);

const temaPadrao = Tema.ambar;

Palette paletteDoTema(Tema t) => switch (t) {
      Tema.ambar => _ambar,
      Tema.begeAreia => _begeAreia,
      Tema.claroAzul => _claroAzul,
      Tema.ameixa => _ameixa,
    };
