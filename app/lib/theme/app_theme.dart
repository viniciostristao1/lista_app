import 'package:flutter/material.dart';

import 'palette.dart';

/// Monta o ThemeData a partir da [Palette] ativa. Claro ou escuro conforme
/// `palette.brightness`. Ponto único de verdade visual (o resto usa AppColors).
ThemeData buildAppTheme(Palette p) {
  final base = ThemeData(brightness: p.brightness, useMaterial3: true);

  // Barra inferior: com navAccent, o fundo é o acento e o texto é onGreen
  // (contraste forte). Senão, fundo neutro (navBg) e acento só no item ativo.
  final navBg = p.navAccent ? p.green : p.navBg;
  final navSel = p.navAccent ? p.onGreen : p.green;
  final navUnsel =
      p.navAccent ? p.onGreen.withValues(alpha: 0.60) : p.dim2;
  final navInd = p.navAccent
      ? p.onGreen.withValues(alpha: 0.20)
      : p.green.withValues(alpha: 0.15);

  return base.copyWith(
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme(
      brightness: p.brightness,
      primary: p.green,
      onPrimary: p.onGreen,
      secondary: p.blue,
      onSecondary: p.onGreen,
      surface: p.surface,
      onSurface: p.text,
      error: p.danger,
      onError: p.onGreen,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: p.text,
      displayColor: p.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: p.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: navBg,
      indicatorColor: navInd,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? navSel : navUnsel,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? navSel : navUnsel,
        );
      }),
    ),
    dividerColor: p.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.surface2,
      contentTextStyle: TextStyle(color: p.text),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
