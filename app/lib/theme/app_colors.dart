import 'package:flutter/material.dart';

import 'palette.dart';

/// Paleta do app. Antes era const (tema único); agora as cores vêm da [Palette]
/// ativa, trocável em tempo real (o usuário escolhe o tema em Configurações).
/// A API `AppColors.xxx` continua igual — só deixou de ser `const`.
abstract final class AppColors {
  /// Paleta ativa (trocada em Configurações). main.dart a seta a cada build.
  static Palette palette = paletteDoTema(temaPadrao);

  static Color get bg => palette.bg;
  static Color get surface => palette.surface;
  static Color get surface2 => palette.surface2;
  static Color get line => palette.line;
  static Color get lineStrong => palette.lineStrong;
  static Color get text => palette.text;
  static Color get dim => palette.dim;
  static Color get dim2 => palette.dim2;

  // === ACENTO (mantém o nome `green` por compatibilidade histórica) ===
  static Color get green => palette.green;
  static Color get onGreen => palette.onGreen;
  static Color get blue => palette.blue;
  static Color get amber => palette.amber;
  static Color get danger => palette.danger;

  // Gradiente dos cards de destaque (economia / resumo do mês) e barra inferior.
  static Color get cardGrad1 => palette.cardGrad1;
  static Color get cardGrad2 => palette.cardGrad2;
  static Color get navBg => palette.navBg;

  /// Cores que o usuário pode escolher para pintar cada mercado. Ficam const —
  /// não dependem do tema (a bolinha do mercado é a mesma em qualquer tema).
  static const mercadoCores = <Color>[
    Color(0xFF4C8DFF), // azul
    Color(0xFF33D17F), // verde
    Color(0xFFE86EC0), // rosa
    Color(0xFFA978FF), // roxo
    Color(0xFF2FC4C4), // teal
    Color(0xFFFF7A5C), // coral
    Color(0xFFF2C14E), // amarelo
    Color(0xFF7C8CFF), // índigo claro
    Color(0xFFD8C6A0), // bege
    Color(0xFFE23B3B), // vermelho forte
    Color(0xFF9A6A45), // marrom
    Color(0xFF2E7D46), // verde escuro
  ];
}
