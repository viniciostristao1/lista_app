import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/l10n/strings.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';

Future<void> mostrarNotaRapida(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _NotaRapidaSheet(),
  );
}

class _LinhaTodo {
  _LinhaTodo({String texto = '', this.feito = false})
      : ctrl = TextEditingController(text: texto),
        foco = FocusNode();

  final TextEditingController ctrl;
  final FocusNode foco;
  bool feito;

  String get texto => ctrl.text;

  void dispose() {
    ctrl.dispose();
    foco.dispose();
  }
}

class _NotaRapidaSheet extends ConsumerStatefulWidget {
  const _NotaRapidaSheet();

  @override
  ConsumerState<_NotaRapidaSheet> createState() => _NotaRapidaSheetState();
}

class _NotaRapidaSheetState extends ConsumerState<_NotaRapidaSheet> {
  late final TextEditingController _ctrl;
  late final FocusNode _focoLivre;
  final List<_LinhaTodo> _linhas = [];
  late final NotaRapidaNotifier _notifier;
  late bool _todo;
  bool _copiadoAgora = false;
  Timer? _copiadoTimer;

  final List<NotaRapida> _historico = [];
  bool _emVoltar = false;
  bool _emBurst = false;
  Timer? _burstTimer;
  late String _prevTexto;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(notaRapidaProvider.notifier);
    final n = ref.read(notaRapidaProvider);
    _ctrl = TextEditingController(text: n.texto);
    _focoLivre = FocusNode();
    _todo = n.todo;
    _prevTexto = n.texto;
    if (_todo) _montarLinhas(n.texto, n.feitos);
    _ctrl.addListener(_onTextoBurst);
  }

  @override
  void dispose() {
    _copiadoTimer?.cancel();
    _burstTimer?.cancel();
    _persistir();
    _ctrl.removeListener(_onTextoBurst);
    _ctrl.dispose();
    _focoLivre.dispose();
    for (final l in _linhas) {
      l.ctrl.removeListener(_onTextoBurst);
      l.dispose();
    }
    super.dispose();
  }

  bool _feitosIguais(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _pushSnapshot(String texto, bool todo, List<bool> feitos) {
    if (_emVoltar) return;
    final snap = NotaRapida(texto: texto, todo: todo, feitos: List<bool>.from(feitos));
    if (_historico.isNotEmpty &&
        _historico.last.texto == snap.texto &&
        _historico.last.todo == snap.todo &&
        _feitosIguais(_historico.last.feitos, snap.feitos)) {
      return;
    }
    _historico.add(snap);
    if (_historico.length > 50) _historico.removeAt(0);
  }

  void _pushImediato() {
    _burstTimer?.cancel();
    _emBurst = false;
    _pushSnapshot(_textoAtual, _todo, _feitosAtual);
  }

  void _onTextoBurst() {
    if (_emVoltar) {
      _prevTexto = _textoAtual;
      return;
    }
    final novo = _textoAtual;
    if (novo == _prevTexto) return;
    if (!_emBurst) {
      _pushSnapshot(_prevTexto, _todo, _feitosAtual);
      _emBurst = true;
    }
    _burstTimer?.cancel();
    _burstTimer = Timer(const Duration(milliseconds: 900), () => _emBurst = false);
    _prevTexto = novo;
    _persistir();
    if (mounted) setState(() {});
  }

  void _montarLinhas(String texto, List<bool> feitos) {
    _descartarLinhas();
    final partes = texto.isEmpty ? [''] : texto.split('\n');
    for (var i = 0; i < partes.length; i++) {
      final l = _LinhaTodo(
        texto: partes[i],
        feito: i < feitos.length ? feitos[i] : false,
      );
      l.ctrl.addListener(_onTextoBurst);
      _linhas.add(l);
    }
  }

  void _descartarLinhas() {
    for (final l in _linhas) {
      l.ctrl.removeListener(_onTextoBurst);
      l.dispose();
    }
    _linhas.clear();
  }

  String get _textoAtual =>
      _todo ? _linhas.map((l) => l.texto).join('\n') : _ctrl.text;

  List<bool> get _feitosAtual =>
      _todo ? _linhas.map((l) => l.feito).toList() : const [];

  void _persistir() {
    _notifier.salvar(NotaRapida(
      texto: _textoAtual,
      todo: _todo,
      feitos: _feitosAtual,
    ));
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _textoAtual));
    setState(() => _copiadoAgora = true);
    _copiadoTimer?.cancel();
    _copiadoTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiadoAgora = false);
    });
  }

  void _limpar() {
    if (_textoAtual.isEmpty && (!_todo || _linhas.length <= 1 && _linhas.isEmpty)) return;
    _pushImediato();
    setState(() {
      _ctrl.clear();
      if (_todo) {
        _descartarLinhas();
        final l = _LinhaTodo();
        l.ctrl.addListener(_onTextoBurst);
        _linhas.add(l);
      }
      _prevTexto = _textoAtual;
    });
    _persistir();
  }

  void _fechar() {
    _persistir();
    Navigator.of(context).pop();
  }

  void _voltar() {
    if (_historico.isEmpty) return;
    _burstTimer?.cancel();
    _emBurst = false;
    final anterior = _historico.removeLast();
    _emVoltar = true;
    setState(() {
      _todo = anterior.todo;
      if (_todo) {
        _descartarLinhas();
        final partes = anterior.texto.isEmpty ? [''] : anterior.texto.split('\n');
        for (var i = 0; i < partes.length; i++) {
          final l = _LinhaTodo(
            texto: partes[i],
            feito: i < anterior.feitos.length ? anterior.feitos[i] : false,
          );
          l.ctrl.addListener(_onTextoBurst);
          _linhas.add(l);
        }
      } else {
        _descartarLinhas();
        _ctrl.value = TextEditingValue(
          text: anterior.texto,
          selection: TextSelection.collapsed(offset: anterior.texto.length),
        );
      }
      _prevTexto = anterior.texto;
    });
    _emVoltar = false;
    _persistir();
    if (_todo && _linhas.isNotEmpty) {
      _focarLinha(_linhas.length - 1);
    } else if (!_todo) {
      _focoLivre.requestFocus();
    }
    setState(() {});
  }

  void _alternarTodo() {
    _pushImediato();
    final indoParaLivre = _todo;
    final textoPreservado = _textoAtual;
    setState(() {
      if (_todo) {
        _ctrl.removeListener(_onTextoBurst);
        _ctrl.value = TextEditingValue(
          text: textoPreservado,
          selection: TextSelection.collapsed(offset: textoPreservado.length),
        );
        _ctrl.addListener(_onTextoBurst);
        _descartarLinhas();
        _todo = false;
      } else {
        _ctrl.removeListener(_onTextoBurst);
        _montarLinhas(_ctrl.text, const []);
        _ctrl.addListener(_onTextoBurst);
        _todo = true;
      }
      _prevTexto = _textoAtual;
    });
    _persistir();
    if (_todo && _linhas.isNotEmpty) {
      _focarLinha(_linhas.length - 1);
    } else if (indoParaLivre) {
      _focoLivre.requestFocus();
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
    setState(() {});
  }

  void _alternarFeito(int i) {
    _pushImediato();
    setState(() => _linhas[i].feito = !_linhas[i].feito);
    _prevTexto = _textoAtual;
    _persistir();
    setState(() {});
  }

  void _novaLinhaApos(int i) {
    _pushImediato();
    final l = _linhas[i];
    final texto = l.ctrl.text;
    final sel = l.ctrl.selection.baseOffset;
    final corte = (sel >= 0 && sel <= texto.length) ? sel : texto.length;
    setState(() {
      l.ctrl.text = texto.substring(0, corte);
      final nl = _LinhaTodo(texto: texto.substring(corte));
      nl.ctrl.addListener(_onTextoBurst);
      _linhas.insert(i + 1, nl);
      _prevTexto = _textoAtual;
    });
    _focarLinha(i + 1, inicio: true);
    _persistir();
  }

  KeyEventResult _aoTeclarLinha(int i, KeyEvent event) {
    final ehBackspace = event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace;
    if (ehBackspace && _linhas[i].texto.isEmpty && _linhas.length > 1) {
      _pushImediato();
      final anteriorIdx = i - 1 >= 0 ? i - 1 : 0;
      final posCursor = i - 1 >= 0 ? _linhas[anteriorIdx].texto.length : 0;
      setState(() {
        final removida = _linhas.removeAt(i);
        removida.ctrl.removeListener(_onTextoBurst);
        removida.dispose();
        _prevTexto = _textoAtual;
      });
      _focarLinha(anteriorIdx, offset: posCursor);
      _persistir();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _focarLinha(int i, {bool inicio = false, int? offset}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || i < 0 || i >= _linhas.length) return;
      final l = _linhas[i];
      l.foco.requestFocus();
      final pos = offset ?? (inicio ? 0 : l.texto.length);
      l.ctrl.selection = TextSelection.collapsed(offset: pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final maxAltura = MediaQuery.of(context).size.height * 0.5;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.dim2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Row(
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 18, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text(t.notaRapida,
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxAltura),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: _todo ? _campoChecklist(t) : _campoLivre(t),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
              child: Row(
                children: [
                  _ferramenta(
                    _copiadoAgora ? Icons.check_rounded : Icons.copy_rounded,
                    _copiadoAgora ? t.copiado : t.copiar,
                    _copiar,
                    ativo: _copiadoAgora,
                  ),
                  _ferramenta(
                    _todo
                        ? Icons.check_box_rounded
                        : Icons.check_box_outlined,
                    t.toDo,
                    _alternarTodo,
                    ativo: _todo,
                  ),
                  _ferramenta(
                    Icons.undo_rounded,
                    t.voltar,
                    _historico.isEmpty ? null : _voltar,
                  ),
                  _ferramenta(
                      Icons.delete_sweep_outlined, t.limpar, _limpar),
                  _ferramenta(Icons.close_rounded, t.fechar, _fechar),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoLivre(AppStrings t) {
    return TextField(
      controller: _ctrl,
      focusNode: _focoLivre,
      autofocus: !_todo,
      minLines: 2,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (_) => _persistir(),
      style: TextStyle(color: AppColors.text, fontSize: 15, height: 1.35),
      decoration: InputDecoration(
        isDense: true,
        border: InputBorder.none,
        hintText: t.notaRapidaHint,
        hintStyle: TextStyle(color: AppColors.dim2, fontSize: 14),
      ),
    );
  }

  Widget _campoChecklist(AppStrings t) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _linhas.length; i++) _linhaChecklist(i, t),
        ],
      ),
    );
  }

  Widget _linhaChecklist(int i, AppStrings t) {
    final l = _linhas[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _checkbox(l.feito, () => _alternarFeito(i)),
          const SizedBox(width: 10),
          Expanded(
            child: Focus(
              onKeyEvent: (_, event) => _aoTeclarLinha(i, event),
              child: TextField(
                controller: l.ctrl,
                focusNode: l.foco,
                autofocus: i == 0 && l.texto.isEmpty,
                maxLines: 1,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                onEditingComplete: () => _novaLinhaApos(i),
                onChanged: (_) => _persistir(),
                style: TextStyle(
                  color: l.feito ? AppColors.dim : AppColors.text,
                  fontSize: 15,
                  height: 1.3,
                  decoration:
                      l.feito ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.dim2,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: i == 0 ? t.notaRapidaHint : null,
                  hintStyle:
                      TextStyle(color: AppColors.dim2, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkbox(bool feito, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: feito ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: feito ? AppColors.green : AppColors.dim2,
            width: 2,
          ),
        ),
        child: feito
            ? Icon(Icons.check, size: 15, color: AppColors.onGreen)
            : null,
      ),
    );
  }

  Widget _ferramenta(IconData icon, String label, VoidCallback? onTap,
      {bool ativo = false}) {
    final enabled = onTap != null;
    final cor = !enabled
        ? AppColors.dim2
        : ativo
            ? AppColors.green
            : AppColors.dim;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: cor),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cor,
                    fontSize: 11.5,
                    fontWeight: ativo ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
