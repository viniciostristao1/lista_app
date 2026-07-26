import 'package:flutter/material.dart';

/// Logo do app: carrinho com dois "V" (checks) em azul claro degradê, fundo
/// azul escuro. É a mesma arte do ícone do app (assets/icon/icon_full.png).
class LogoLista extends StatelessWidget {
  const LogoLista({super.key, this.size = 84});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/icon_full.png',
      width: size,
      height: size,
    );
  }
}
