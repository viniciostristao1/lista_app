import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Abre o editor "Meus mercados" (até 3, com nome e cor).
Future<void> mostrarEditorMercados(BuildContext context, List<Mercado> atuais) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditorMercados(atuais: atuais),
  );
}

class _Slot {
  _Slot(
      {this.id,
      required String nome,
      required this.cor,
      this.preferencia = false,
      this.novo = false})
      : nomeCtrl = TextEditingController(text: nome);
  final String? id;
  final TextEditingController nomeCtrl;
  Color cor;
  bool preferencia;
  bool novo; // recém-adicionado → autofoca o campo
}

class _EditorMercados extends ConsumerStatefulWidget {
  const _EditorMercados({required this.atuais});
  final List<Mercado> atuais;

  @override
  ConsumerState<_EditorMercados> createState() => _EditorMercadosState();
}

class _EditorMercadosState extends ConsumerState<_EditorMercados> {
  static const _maxMercados = 8;
  late List<_Slot> _slots;
  late Set<String> _idsIniciais;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _slots = widget.atuais
        .map((m) => _Slot(
            id: m.id, nome: m.nome, cor: m.cor, preferencia: m.preferencia))
        .toList();
    _idsIniciais = widget.atuais.map((m) => m.id).toSet();
  }

  // Só um mercado pode ser preferência: marca este e desmarca os outros.
  void _togglePreferencia(int i) {
    setState(() {
      final novo = !_slots[i].preferencia;
      for (final s in _slots) {
        s.preferencia = false;
      }
      _slots[i].preferencia = novo;
    });
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.nomeCtrl.dispose();
    }
    super.dispose();
  }

  void _adicionar() {
    if (_slots.length >= _maxMercados) return;
    setState(() {
      final cor = AppColors.mercadoCores[_slots.length % AppColors.mercadoCores.length];
      _slots.add(_Slot(nome: '', cor: cor, novo: true));
    });
  }

  void _remover(int i) {
    setState(() {
      _slots.removeAt(i).nomeCtrl.dispose();
    });
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final repo = ref.read(mercadosRepoProvider);
    try {
      final restantes = _slots.where((s) => s.id != null).map((s) => s.id!).toSet();
      for (final id in _idsIniciais) {
        if (!restantes.contains(id)) {
          await repo.excluir(id);
          // some com os preços desse mercado em todos os produtos
          await ref.read(produtosRepoProvider).removerMercadoDeTodos(id);
        }
      }
      for (final s in _slots) {
        final nome = s.nomeCtrl.text.trim();
        if (nome.isEmpty) continue;
        if (s.id == null) {
          await repo.criar(nome: nome, cor: s.cor, preferencia: s.preferencia);
        } else {
          await repo.atualizar(s.id!,
              nome: nome, cor: s.cor, preferencia: s.preferencia);
        }
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // empurra a folha pra cima do teclado
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        // limita a altura; a lista rola, o botão Salvar fica fixo embaixo
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.dim2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(t.meusMercados,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(t.mercadosDescricao,
                style: const TextStyle(color: AppColors.dim, fontSize: 12.5)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _slots.length; i++) _linha(i),
                    if (_slots.length < _maxMercados)
                      TextButton.icon(
                        onPressed: _adicionar,
                        icon: const Icon(Icons.add,
                            size: 18, color: AppColors.green),
                        label: Text(t.adicionarMercado,
                            style: const TextStyle(color: AppColors.green)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.onGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_salvando ? t.salvando : t.salvarMercados),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(int i) {
    final t = ref.watch(stringsProvider);
    final slot = _slots[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: slot.cor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: slot.nomeCtrl,
                  autofocus: slot.novo,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: t.nomeDoMercado,
                    hintStyle: const TextStyle(color: AppColors.dim2),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _remover(i),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.dim2, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cor in AppColors.mercadoCores)
                GestureDetector(
                  onTap: () => setState(() => slot.cor = cor),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slot.cor == cor
                            ? AppColors.text
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _togglePreferencia(i),
            child: Row(
              children: [
                Icon(slot.preferencia ? Icons.star : Icons.star_border,
                    size: 18,
                    color:
                        slot.preferencia ? AppColors.green : AppColors.dim2),
                const SizedBox(width: 6),
                Text(
                  slot.preferencia
                      ? t.preferenciaItensVemPraCa
                      : t.definirComoPreferencia,
                  style: TextStyle(
                      color:
                          slot.preferencia ? AppColors.green : AppColors.dim,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
