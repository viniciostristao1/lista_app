import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/categoria.dart';

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

/// Ordem em que as categorias aparecem na lista (o usuário arruma pra seguir
/// o caminho dele no mercado). Guardada no aparelho; categorias novas entram
/// no fim automaticamente.
class CategoriaOrdemNotifier extends Notifier<List<Categoria>> {
  static const _key = 'ordemCategorias';

  @override
  List<Categoria> build() {
    _restaurar();
    return Categoria.values.toList();
  }

  Future<void> _restaurar() async {
    final p = await SharedPreferences.getInstance();
    final nomes = p.getStringList(_key);
    if (nomes == null) return;
    final ord = <Categoria>[];
    for (final n in nomes) {
      for (final c in Categoria.values) {
        if (c.name == n && !ord.contains(c)) {
          ord.add(c);
          break;
        }
      }
    }
    for (final c in Categoria.values) {
      if (!ord.contains(c)) ord.add(c); // categorias novas vão pro fim
    }
    state = ord;
  }

  Future<void> definir(List<Categoria> ordem) async {
    state = List.of(ordem);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_key, ordem.map((c) => c.name).toList());
  }
}

final categoriaOrdemProvider =
    NotifierProvider<CategoriaOrdemNotifier, List<Categoria>>(
        CategoriaOrdemNotifier.new);
