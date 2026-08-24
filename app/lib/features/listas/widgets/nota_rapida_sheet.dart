import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Caixinha de "nota rápida / recado": um campo de texto que cresce conforme o
/// usuário dá enter ou escreve mais linhas, com uma barra de ferramentas
/// (copiar, limpar, fechar, to do). O "to do" liga/desliga uma caixinha de
/// seleção única — igual aos itens da lista, dá pra marcar e desmarcar.
/// Persiste no aparelho via [notaRapidaProvider] (ver prefs.dart).
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

class _NotaRapidaSheet extends ConsumerStatefulWidget {
  const _NotaRapidaSheet();

  @override
  ConsumerState<_NotaRapidaSheet> createState() => _NotaRapidaSheetState();
}

class _NotaRapidaSheetState extends ConsumerState<_NotaRapidaSheet> {
  late final TextEditingController _ctrl;
  // Capturado no initState pra poder gravar no dispose sem tocar em `ref` lá.
  late final NotaRapidaNotifier _notifier;
  late bool _todo;
  late bool _feito;

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
    _todo = n.todo;
    _feito = n.feito;
  }

  @override
  void dispose() {
    _copiadoTimer?.cancel();
    // Backup: garante que a última edição de texto seja salva mesmo se a folha
    // for fechada arrastando pra baixo (sem passar pelo botão "Fechar").
    _persistir();
    _ctrl.dispose();
    super.dispose();
  }

  void _persistir() {
    _notifier.salvar(NotaRapida(
      texto: _ctrl.text,
      todo: _todo,
      feito: _feito,
    ));
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _ctrl.text));
    setState(() => _copiadoAgora = true);
    _copiadoTimer?.cancel();
    _copiadoTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiadoAgora = false);
    });
  }

  void _limpar() {
    setState(() {
      _ctrl.clear();
      _feito = false;
    });
    _persistir();
  }

  void _fechar() {
    _persistir();
    Navigator.of(context).pop();
  }

  // Liga/desliga a caixinha de seleção. Ao desligar, some a seleção (e zera o
  // "marcado", pra não voltar marcada da próxima vez).
  void _alternarTodo() {
    setState(() {
      _todo = !_todo;
      if (!_todo) _feito = false;
    });
    _persistir();
  }

  void _alternarFeito() {
    setState(() => _feito = !_feito);
    _persistir();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final maxAltura = MediaQuery.of(context).size.height * 0.5;

    return SafeArea(
      child: Padding(
        // Sobe junto com o teclado.
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
            // Campo do recado (cresce com o texto até um teto, depois rola).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Container(
                constraints: BoxConstraints(maxHeight: maxAltura),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_todo) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _checkbox(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        minLines: 2,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: _feito ? AppColors.dim : AppColors.text,
                          fontSize: 15,
                          height: 1.35,
                          decoration:
                              _feito ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.dim2,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: t.notaRapidaHint,
                          hintStyle:
                              TextStyle(color: AppColors.dim2, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
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

  // Caixinha de seleção do recado — mesmo visual do checkbox dos itens.
  Widget _checkbox() {
    return GestureDetector(
      onTap: _alternarFeito,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: _feito ? AppColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: _feito ? AppColors.green : AppColors.dim2,
            width: 2,
          ),
        ),
        child: _feito
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
