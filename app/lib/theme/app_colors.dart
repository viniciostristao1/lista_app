import 'package:flutter/material.dart';

/// Paleta do app (tema escuro), derivada da maquete.
abstract final class AppColors {
  static const bg = Color(0xFF0E0F13); // fundo
  static const surface = Color(0xFF191C22); // cards
  static const surface2 = Color(0xFF212530); // hover / elevação
  // FLAT: sem contorno de cards (transparente). A separação vem do contraste
  // bg↔surface. `lineStrong` guarda só as arestas estruturais (stepper/inputs).
  static const line = Color(0x00FFFFFF); // transparente
  static const lineStrong = Color(0x14FFFFFF); // ~8% branco

  static const text = Color(0xFFEDEFF3); // texto principal
  static const dim = Color(0xFF8B93A1); // texto secundário
  static const dim2 = Color(0xFF5F6674); // texto terciário / ícones apagados

  // === ACENTO = âmbar (escolha do usuário 2026-07-31) ===
  // (mantém o nome `green` por compatibilidade; é o acento do app)
  static const green = Color(0xFFE0A24A); // âmbar quente
  static const onGreen = Color(0xFF201603); // texto sobre o acento
  static const blue = Color(0xFF4C8DFF); // ações
  static const amber = Color(0xFFF2B84B);
  static const danger = Color(0xFFFF7A7A);

  /// Cores que o usuário pode escolher para pintar cada mercado (distintas
  /// entre si; não usam o âmbar do acento pra não confundir).
  static const mercadoCores = <Color>[
    Color(0xFF4C8DFF), // azul
    Color(0xFF33D17F), // verde
    Color(0xFFE86EC0), // rosa
    Color(0xFFA978FF), // roxo
    Color(0xFF2FC4C4), // teal
    Color(0xFFFF7A5C), // coral
    Color(0xFFF2C14E), // amarelo
    Color(0xFF7C8CFF), // índigo claro
  ];
}
