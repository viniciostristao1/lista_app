import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Escala de fonte do app, escolhida pelo usuário e guardada no aparelho.
/// Fatores sobre o texto-base (~14,5): 0.93 = Menor (~13,5) · 1.035 = Normal
/// (~15) · 1.22 = Maior (~17,7).
class FontScaleNotifier extends Notifier<double> {
  static const _key = 'fontScale';

  @override
  double build() {
    _restaurar();
    return 1.035;
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
