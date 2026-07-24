import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/services/mercados_repository.dart';
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
  _Slot({this.id, required String nome, required this.cor})
      : nomeCtrl = TextEditingController(text: nome);
  final String? id;
  final TextEditingController nomeCtrl;
  Color cor;
}

class _EditorMercados extends ConsumerStatefulWidget {
  const _EditorMercados({required this.atuais});
  final List<Mercado> atuais;

  @override
  ConsumerState<_EditorMercados> createState() => _EditorMercadosState();
}

class _EditorMercadosState extends ConsumerState<_EditorMercados> {
  late List<_Slot> _slots;
  late Set<String> _idsIniciais;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _slots = widget.atuais
        .map((m) => _Slot(id: m.id, nome: m.nome, cor: m.cor))
        .toList();
    _idsIniciais = widget.atuais.map((m) => m.id).toSet();
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.nomeCtrl.dispose();
    }
    super.dispose();
  }

  void _adicionar() {
    if (_slots.length >= 3) return;
    setState(() {
      final cor = AppColors.mercadoCores[_slots.length % AppColors.mercadoCores.length];
      _slots.add(_Slot(nome: '', cor: cor));
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
        if (!restantes.contains(id)) await repo.excluir(id);
      }
      for (final s in _slots) {
        final nome = s.nomeCtrl.text.trim();
        if (nome.isEmpty) continue;
        if (s.id == null) {
          await repo.criar(nome: nome, cor: s.cor);
        } else {
          await repo.atualizar(s.id!, nome: nome, cor: s.cor);
        }
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 10, bottom: bottom + 24),
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
          const Text('Meus mercados',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('Até 3 favoritos. Toque numa cor para trocar.',
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          const SizedBox(height: 14),
          for (var i = 0; i < _slots.length; i++) _linha(i),
          if (_slots.length < 3)
            TextButton.icon(
              onPressed: _adicionar,
              icon: const Icon(Icons.add, size: 18, color: AppColors.green),
              label: const Text('Adicionar mercado',
                  style: TextStyle(color: AppColors.green)),
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
              child: Text(_salvando ? 'Salvando…' : 'Salvar mercados'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linha(int i) {
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
                  style: const TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Nome do mercado',
                    hintStyle: TextStyle(color: AppColors.dim2),
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
          Row(
            children: [
              for (final cor in AppColors.mercadoCores)
                GestureDetector(
                  onTap: () => setState(() => slot.cor = cor),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
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
        ],
      ),
    );
  }
}
