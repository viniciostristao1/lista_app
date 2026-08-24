import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/categoria.dart';
import '../theme/palette.dart';

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

/// Idioma do app. Guardado no aparelho. Padrão na 1ª vez: segue o idioma do
/// aparelho (pt → português, es → espanhol; senão inglês).
class IdiomaNotifier extends Notifier<Idioma> {
  static const _key = 'idioma';

  /// Chave antiga (booleano `en`) — só para migrar quem já escolheu inglês.
  static const _keyLegacy = 'idiomaEn';

  @override
  Idioma build() {
    _restaurar();
    final loc =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return switch (loc) {
      'pt' => Idioma.pt,
      'es' => Idioma.es,
      _ => Idioma.en,
    };
  }

  Future<void> _restaurar() async {
    final p = await SharedPreferences.getInstance();
    // Migração única da chave antiga (booleano `en`): converte e apaga, pra
    // não ter prioridade eterna sobre a escolha nova de idioma.
    final legado = p.getBool(_keyLegacy);
    if (legado != null) {
      state = legado ? Idioma.en : Idioma.pt;
      await p.remove(_keyLegacy);
      await p.setString(_key, state.name);
      return;
    }
    final v = p.getString(_key);
    if (v == null) return;
    for (final i in Idioma.values) {
      if (i.name == v) {
        state = i;
        return;
      }
    }
  }

  Future<void> definir(Idioma idioma) async {
    state = idioma;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, idioma.name);
  }
}

final idiomaProvider = NotifierProvider<IdiomaNotifier, Idioma>(IdiomaNotifier.new);

/// Textos do app no idioma atual. Assista este provider e use `t.xxx`.
final stringsProvider =
    Provider<AppStrings>((ref) => AppStrings(ref.watch(idiomaProvider)));

/// Tema escolhido pelo usuário (cores do app). Guardado no aparelho.
class TemaNotifier extends Notifier<Tema> {
  static const _key = 'tema';

  @override
  Tema build() {
    _restaurar();
    return temaPadrao;
  }

  Future<void> _restaurar() async {
    final p = await SharedPreferences.getInstance();
    final nome = p.getString(_key);
    if (nome == null) return;
    for (final t in Tema.values) {
      if (t.name == nome) {
        state = t;
        return;
      }
    }
  }

  Future<void> definir(Tema t) async {
    state = t;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, t.name);
  }
}

final temaProvider = NotifierProvider<TemaNotifier, Tema>(TemaNotifier.new);

/// Nota rápida / recado do usuário: texto livre (fora das listas) + modo
/// "to do" (uma caixinha de seleção única que pode ser marcada/desmarcada,
/// igual aos itens da lista). Guardada no aparelho.
class NotaRapida {
  const NotaRapida({this.texto = '', this.todo = false, this.feitos = const []});

  final String texto;

  /// Modo "to do" ligado: cada linha do recado vira um item com caixinha.
  final bool todo;

  /// Marcado por LINHA (alinhado por índice às linhas de [texto]); só vale
  /// quando [todo] está ligado.
  final List<bool> feitos;

  NotaRapida copyWith({String? texto, bool? todo, List<bool>? feitos}) =>
      NotaRapida(
        texto: texto ?? this.texto,
        todo: todo ?? this.todo,
        feitos: feitos ?? this.feitos,
      );
}

/// Nota rápida persistida no aparelho. Ninguém `watch`a este provider (só a
/// própria caixinha o lê/grava), então gravar ao fechar a folha é seguro.
class NotaRapidaNotifier extends Notifier<NotaRapida> {
  static const _kTexto = 'notaRapidaTexto';
  static const _kTodo = 'notaRapidaTodo';
  static const _kFeitos = 'notaRapidaFeitos'; // '1'/'0' por linha

  @override
  NotaRapida build() {
    _restaurar();
    return const NotaRapida();
  }

  Future<void> _restaurar() async {
    final p = await SharedPreferences.getInstance();
    final feitos =
        (p.getStringList(_kFeitos) ?? const []).map((e) => e == '1').toList();
    state = NotaRapida(
      texto: p.getString(_kTexto) ?? '',
      todo: p.getBool(_kTodo) ?? false,
      feitos: feitos,
    );
  }

  Future<void> salvar(NotaRapida n) async {
    state = n;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTexto, n.texto);
    await p.setBool(_kTodo, n.todo);
    await p.setStringList(
        _kFeitos, n.feitos.map((f) => f ? '1' : '0').toList());
  }
}

final notaRapidaProvider =
    NotifierProvider<NotaRapidaNotifier, NotaRapida>(NotaRapidaNotifier.new);
