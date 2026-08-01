import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escala de fonte do app, escolhida pelo usuário e guardada no aparelho.
/// 0.9 = Menor · 1.0 = Normal · 1.2 = Maior.
class FontScaleNotifier extends Notifier<double> {
  static const _key = 'fontScale';

  @override
  double build() {
    _restaurar();
    return 1.0;
  }

  Future<void> _restaurar() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getDouble(_key);
    if (v != null) state = v;
  }

  Future<void> definir(double v) async {
    state = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_key, v);
  }
}

final fontScaleProvider =
    NotifierProvider<FontScaleNotifier, double>(FontScaleNotifier.new);
