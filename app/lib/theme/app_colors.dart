import 'package:flutter/material.dart';

/// Paleta do app (tema escuro), derivada da maquete.
abstract final class AppColors {
  static const bg = Color(0xFF0E0F13); // fundo
  static const surface = Color(0xFF191C22); // cards
  static const surface2 = Color(0xFF212530); // hover / elevação
  static const line = Color(0x12FFFFFF); // divisórias ~7% branco
  static const lineStrong = Color(0x1FFFFFFF); // ~12% branco

  static const text = Color(0xFFEDEFF3); // texto principal
  static const dim = Color(0xFF8B93A1); // texto secundário
  static const dim2 = Color(0xFF5F6674); // texto terciário / ícones apagados

  static const green = Color(0xFF33D17F); // economia / sucesso / destaque
  static const onGreen = Color(0xFF08130C); // texto sobre verde
  static const blue = Color(0xFF4C8DFF); // ações
  static const amber = Color(0xFFF2B84B);
  static const danger = Color(0xFFFF7A7A);

  /// Cores que o usuário pode escolher para pintar cada mercado.
  static const mercadoCores = <Color>[
    green,
    blue,
    amber,
    Color(0xFFE86EC0), // rosa
    Color(0xFFA978FF), // roxo
  ];
}
