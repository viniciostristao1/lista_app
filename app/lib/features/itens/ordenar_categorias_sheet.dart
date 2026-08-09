import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Abre a folha para o usuário arrastar e reordenar as categorias (a ordem em
/// que aparecem agrupadas na aba Listas — pra seguir o caminho do mercado).
Future<void> mostrarOrdenarCategorias(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _OrdenarCategorias(),
  );
}

class _OrdenarCategorias extends ConsumerStatefulWidget {
  const _OrdenarCategorias();

  @override
  ConsumerState<_OrdenarCategorias> createState() => _OrdenarCategoriasState();
}

class _OrdenarCategoriasState extends ConsumerState<_OrdenarCategorias> {
  late List<Categoria> _ordem;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _ordem = List.of(ref.read(categoriaOrdemProvider));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
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
          const Text('Ordenar categorias',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
              'Arraste pra deixar na ordem do seu mercado — o que você pega '
              'primeiro fica em cima. Vale pra lista toda.',
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          const SizedBox(height: 12),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              itemCount: _ordem.length,
              onReorderItem: (oldI, newI) => setState(() {
                _ordem.insert(newI, _ordem.removeAt(oldI));
              }),
              itemBuilder: (ctx, i) {
                final c = _ordem[i];
                return Padding(
                  key: ValueKey(c.name),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(c.icone, size: 20, color: AppColors.dim),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(c.label,
                              style: const TextStyle(
                                  color: AppColors.text, fontSize: 15)),
                        ),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.drag_handle,
                                color: AppColors.dim2, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _salvando
                  ? null
                  : () async {
                      setState(() => _salvando = true);
                      await ref
                          .read(categoriaOrdemProvider.notifier)
                          .definir(_ordem);
                      if (context.mounted) Navigator.pop(context);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.onGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_salvando ? 'Salvando…' : 'Salvar ordem'),
            ),
          ),
        ],
      ),
    );
  }
}
