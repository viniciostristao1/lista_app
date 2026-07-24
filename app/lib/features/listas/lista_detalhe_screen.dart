import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/listas/widgets/add_item_sheet.dart';
import 'package:lista_app/features/listas/widgets/mercados_editor_sheet.dart';
import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/item_lista.dart';
import 'package:lista_app/models/lista.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

class ListaDetalheScreen extends ConsumerWidget {
  const ListaDetalheScreen({super.key, required this.lista});
  final Lista lista;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itensAsync = ref.watch(itensProvider(lista.id));
    final mercados = ref.watch(mercadosProvider).asData?.value ?? [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    return Scaffold(
      appBar: AppBar(
        title: Text(lista.nome),
        actions: [
          PopupMenuButton<String>(
            color: AppColors.surface2,
            icon: const Icon(Icons.more_vert, color: AppColors.dim),
            onSelected: (v) {
              if (v == 'renomear') _renomear(context, ref);
              if (v == 'excluir') _excluir(context, ref);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'renomear', child: Text('Renomear lista')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir lista')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.onGreen,
        onPressed: () => mostrarAdicionarItem(context, lista.id),
        child: const Icon(Icons.add),
      ),
      body: itensAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.green)),
        error: (_, _) => const Center(
            child: Text('Erro ao carregar itens.',
                style: TextStyle(color: AppColors.dim))),
        data: (itens) => _corpo(context, ref, itens, mercados, mercadosPorId),
      ),
    );
  }

  Widget _corpo(
    BuildContext context,
    WidgetRef ref,
    List<ItemLista> itens,
    List<Mercado> mercados,
    Map<String, Mercado> mercadosPorId,
  ) {
    final comprados = itens.where((e) => e.comprado).toList();
    final total = comprados.fold<double>(0, (s, e) => s + e.subtotal);
    final tudoComprado = itens.isNotEmpty && comprados.length == itens.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _legenda(context, mercados),
              const SizedBox(height: 14),
              _cardTotal(total, comprados.length, itens.length),
              const SizedBox(height: 8),
              if (itens.isEmpty)
                _vazio()
              else
                ..._porCategoria(context, ref, itens, mercadosPorId),
            ],
          ),
        ),
        if (itens.isNotEmpty)
          _botaoFinalizar(context, ref, itens, tudoComprado, comprados.length),
      ],
    );
  }

  // ---- legenda de mercados ----
  Widget _legenda(BuildContext context, List<Mercado> mercados) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => mostrarEditorMercados(context, mercados),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: mercados.isEmpty
                  ? const Text('Toque para cadastrar seus mercados',
                      style: TextStyle(color: AppColors.dim, fontSize: 12.5))
                  : Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        for (final m in mercados)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 7),
                                decoration: BoxDecoration(
                                    color: m.cor, shape: BoxShape.circle),
                              ),
                              Text(m.nome,
                                  style: const TextStyle(
                                      color: AppColors.dim, fontSize: 12.5)),
                            ],
                          ),
                      ],
                    ),
            ),
            const Row(
              children: [
                Icon(Icons.edit_outlined, size: 13, color: AppColors.dim2),
                SizedBox(width: 4),
                Text('editar',
                    style: TextStyle(color: AppColors.dim2, fontSize: 11.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- card do total ----
  Widget _cardTotal(double total, int comprados, int totalItens) {
    final pct = totalItens == 0 ? 0.0 : comprados / totalItens;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2128), Color(0xFF171A20)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reais(total),
              style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 32,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('$comprados de $totalItens itens comprados',
              style: const TextStyle(color: AppColors.dim, fontSize: 13)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: const Color(0xFF0F1116),
              valueColor: const AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
        ],
      ),
    );
  }

  // ---- itens agrupados por categoria ----
  List<Widget> _porCategoria(
    BuildContext context,
    WidgetRef ref,
    List<ItemLista> itens,
    Map<String, Mercado> mercadosPorId,
  ) {
    final widgets = <Widget>[];
    for (final cat in Categoria.values) {
      final doGrupo = itens.where((e) => e.categoria == cat).toList();
      if (doGrupo.isEmpty) continue;
      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(cat.label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.dim2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      ));
      for (final it in doGrupo) {
        widgets.add(_itemRow(context, ref, it, mercadosPorId));
      }
    }
    return widgets;
  }

  Widget _itemRow(
    BuildContext context,
    WidgetRef ref,
    ItemLista it,
    Map<String, Mercado> mercadosPorId,
  ) {
    final cor = it.mercadoId == null ? null : mercadosPorId[it.mercadoId]?.cor;
    return Dismissible(
      key: ValueKey(it.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) =>
          ref.read(listasRepoProvider).removerItem(lista.id, it.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref
            .read(listasRepoProvider)
            .setComprado(lista.id, it.id, !it.comprado),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _checkbox(it.comprado),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  it.quantidade > 1 ? '${it.nome}  ×${it.quantidade}' : it.nome,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: it.comprado ? AppColors.dim : AppColors.text,
                    decoration:
                        it.comprado ? TextDecoration.lineThrough : null,
                    decorationColor: AppColors.dim2,
                  ),
                ),
              ),
              Text(
                it.preco == null ? '—' : reais(it.subtotal),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: it.preco == null ? FontWeight.w400 : FontWeight.w600,
                  color: it.preco == null
                      ? AppColors.dim2
                      : (it.comprado ? AppColors.green : AppColors.text),
                ),
              ),
              if (cor != null) ...[
                const SizedBox(width: 10),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkbox(bool marcado) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: marcado ? AppColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: marcado ? AppColors.green : AppColors.dim2,
          width: 2,
        ),
      ),
      child: marcado
          ? const Icon(Icons.check, size: 15, color: AppColors.onGreen)
          : null,
    );
  }

  Widget _vazio() {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.add_shopping_cart_outlined,
              size: 44, color: AppColors.dim2),
          SizedBox(height: 14),
          Text('Lista vazia',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Toque no + para adicionar o primeiro item.',
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _botaoFinalizar(
    BuildContext context,
    WidgetRef ref,
    List<ItemLista> itens,
    bool habilitado,
    int comprados,
  ) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: habilitado
              ? () async {
                  await ref.read(listasRepoProvider).finalizar(lista.id, itens);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compra finalizada! 🛒')),
                    );
                  }
                }
              : null,
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(habilitado
              ? 'Finalizar compra'
              : 'Finalizar ($comprados/${itens.length})'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green.withValues(alpha: 0.14),
            foregroundColor: AppColors.green,
            disabledBackgroundColor: AppColors.surface,
            disabledForegroundColor: AppColors.dim2,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Future<void> _renomear(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController(text: lista.nome);
    final novo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Renomear lista'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Salvar')),
        ],
      ),
    );
    if (novo != null && novo.isNotEmpty) {
      await ref.read(listasRepoProvider).renomear(lista.id, novo);
    }
  }

  Future<void> _excluir(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir lista?'),
        content: const Text('Isso apaga a lista e seus itens. Não dá pra desfazer.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(listasRepoProvider).excluir(lista.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}
