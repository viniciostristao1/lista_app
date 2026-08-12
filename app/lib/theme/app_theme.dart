import 'package:flutter/material.dart';

import 'palette.dart';

/// Monta o ThemeData a partir da [Palette] ativa. Claro ou escuro conforme
/// `palette.brightness`. Ponto único de verdade visual (o resto usa AppColors).
ThemeData buildAppTheme(Palette p) {
  final base = ThemeData(brightness: p.brightness, useMaterial3: true);

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
      backgroundColor: p.navBg,
      indicatorColor: p.green.withValues(alpha: 0.15),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? p.green : p.dim2,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? p.green : p.dim2,
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
