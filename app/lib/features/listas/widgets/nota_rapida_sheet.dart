import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/l10n/strings.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Caixinha de "nota rápida / recado": um campo de texto que cresce conforme o
/// usuário dá enter ou escreve mais linhas, com uma barra de ferramentas
/// (copiar, limpar, fechar, to do). O "to do" transforma o recado numa
/// **checklist**: cada linha vira um item com sua própria caixinha de seleção
/// (marca/desmarca igual aos itens da lista); dar **enter** cria uma nova linha
/// marcável, e **backspace** numa linha vazia junta com a de cima. Persiste no
/// aparelho via [notaRapidaProvider] (ver prefs.dart).
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

/// Uma linha da checklist no modo "to do": texto (com controller/foco próprios)
/// + estado marcado.
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

  // Feedback visível do "Copiar" (um snackbar ficaria escondido atrás da
  // folha): o botão vira ✓ "Copiado!" por ~1,2s.
  bool _copiadoAgora = false;
  Timer? _copiadoTimer;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(notaRapidaProvider.notifier);
    final n = ref.read(notaRapidaProvider);
    _ctrl = TextEditingController(text: n.texto);
    _focoLivre = FocusNode();
    _todo = n.todo;
    if (_todo) _montarLinhas(n.texto, n.feitos);
  }

  @override
  void dispose() {
    _copiadoTimer?.cancel();
    _persistir();
    _ctrl.dispose();
    _focoLivre.dispose();
    for (final l in _linhas) {
      l.dispose();
    }
    super.dispose();
  }

  // ---------- conversão texto livre <-> checklist ----------

  // Cria as linhas da checklist a partir do texto (uma por '\n'). O marcado
  // de cada linha vem de [feitos] (alinhado por índice), senão desmarcado.
  void _montarLinhas(String texto, List<bool> feitos) {
    _descartarLinhas();
    final partes = texto.isEmpty ? [''] : texto.split('\n');
    for (var i = 0; i < partes.length; i++) {
      _linhas.add(_LinhaTodo(
        texto: partes[i],
        feito: i < feitos.length ? feitos[i] : false,
      ));
    }
  }

  void _descartarLinhas() {
    for (final l in _linhas) {
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

  // ---------- ações da barra ----------

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _textoAtual));
    setState(() => _copiadoAgora = true);
    _copiadoTimer?.cancel();
    _copiadoTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiadoAgora = false);
    });
  }

  void _limpar() {
    setState(() {
      _ctrl.clear();
      if (_todo) {
        _descartarLinhas();
        _linhas.add(_LinhaTodo());
      }
    });
    _persistir();
  }

  void _fechar() {
    _persistir();
    Navigator.of(context).pop();
  }

  void _alternarTodo() {
    final indoParaLivre = _todo;
    final textoPreservado = _textoAtual;
    setState(() {
      if (_todo) {
        _ctrl.value = TextEditingValue(
          text: textoPreservado,
          selection: TextSelection.collapsed(offset: textoPreservado.length),
        );
        _descartarLinhas();
        _todo = false;
      } else {
        _montarLinhas(_ctrl.text, const []);
        _todo = true;
      }
    });
    _persistir();
    if (_todo && _linhas.isNotEmpty) {
      _focarLinha(_linhas.length - 1);
    } else if (indoParaLivre) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focoLivre.requestFocus();
        _ctrl.selection =
            TextSelection.collapsed(offset: _ctrl.text.length);
      });
    }
  }

  void _alternarFeito(int i) {
    setState(() => _linhas[i].feito = !_linhas[i].feito);
    _persistir();
  }

  // ---------- edição das linhas da checklist ----------

  // Enter (onSubmitted) numa linha cria a PRÓXIMA linha marcável. O texto após
  // o cursor migra pra linha nova (Enter no fim = linha nova vazia). Usar
  // onSubmitted (e não detectar '\n' no onChanged) é o que funciona igual nos
  // teclados virtual e físico — é o mesmo padrão do campo de busca do app.
  void _novaLinhaApos(int i) {
    final l = _linhas[i];
    final texto = l.ctrl.text;
    final sel = l.ctrl.selection.baseOffset;
    final corte = (sel >= 0 && sel <= texto.length) ? sel : texto.length;
    setState(() {
      l.ctrl.text = texto.substring(0, corte);
      _linhas.insert(i + 1, _LinhaTodo(texto: texto.substring(corte)));
    });
    _focarLinha(i + 1, inicio: true);
    _persistir();
  }

  // Backspace no começo de uma linha VAZIA junta com a linha de cima (remove a
  // linha atual e leva o cursor pro fim da anterior). Best-effort: em alguns
  // teclados virtuais o backspace-em-vazio pode não chegar como evento — aí a
  // linha só fica vazia (sem quebrar nada).
  KeyEventResult _aoTeclarLinha(int i, KeyEvent event) {
    final ehBackspace = event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace;
    if (ehBackspace && _linhas[i].texto.isEmpty && _linhas.length > 1) {
      final anteriorIdx = i - 1 >= 0 ? i - 1 : 0;
      final posCursor = i - 1 >= 0 ? _linhas[anteriorIdx].texto.length : 0;
      setState(() {
        final removida = _linhas.removeAt(i);
        removida.dispose();
      });
      _focarLinha(anteriorIdx, offset: posCursor);
      _persistir();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Foca a linha [i] após o frame (a árvore precisa existir primeiro).
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
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
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
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
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
            ),
            // Barra de ferramentas.
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
                      Icons.delete_sweep_outlined, t.limpar, _limpar),
                  _ferramenta(Icons.close_rounded, t.fechar, _fechar),
                  _ferramenta(
                    _todo
                        ? Icons.check_box_rounded
                        : Icons.check_box_outlined,
                    t.toDo,
                    _alternarTodo,
                    ativo: _todo,
                  ),
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

  // Checklist: uma linha marcável por item (rola quando passa do teto).
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
                // Mantém o teclado aberto e cria a próxima linha (não deixa o
                // "next" padrão pular o foco pra outro campo).
                onEditingComplete: () => _novaLinhaApos(i),
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

  // Caixinha de seleção — mesmo visual do checkbox dos itens da lista.
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

  // Um botão da barra de ferramentas: ícone em cima, rótulo embaixo. Quando
  // "ativo" (caso do to do ligado), pinta de verde.
  Widget _ferramenta(IconData icon, String label, VoidCallback onTap,
      {bool ativo = false}) {
    final cor = ativo ? AppColors.green : AppColors.dim;
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
