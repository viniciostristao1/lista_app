import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/produto_editor_screen.dart';
import 'package:lista_app/features/listas/widgets/mercados_editor_sheet.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

class ItensScreen extends ConsumerStatefulWidget {
  const ItensScreen({super.key});

  @override
  ConsumerState<ItensScreen> createState() => _ItensScreenState();
}

class _ItensScreenState extends ConsumerState<ItensScreen> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtosProvider);
    final mercados = ref.watch(mercadosProvider).asData?.value ?? [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v.trim().toLowerCase()),
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar item…',
                hintStyle: const TextStyle(color: AppColors.dim2),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.dim, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.onGreen,
        onPressed: () => mostrarEditorProduto(context, null, mercados),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              children: [
                _boxEditar(
                  icon: Icons.storefront_outlined,
                  label: 'Editar mercados',
                  onTap: () => mostrarEditorMercados(context, mercados),
                ),
              ],
            ),
          ),
          Expanded(
            child: produtosAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green)),
              error: (_, _) => const Center(
                  child: Text('Erro ao carregar.',
                      style: TextStyle(color: AppColors.dim))),
              data: (todos) {
                final lista = _busca.isEmpty
                    ? todos
                    : todos.where((p) => p.nomeLower.contains(_busca)).toList();
                if (todos.isEmpty) return _vazio();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: lista.length,
                  itemBuilder: (_, i) =>
                      _cardProduto(lista[i], mercados, mercadosPorId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxEditar({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.green),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: AppColors.dim, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _cardProduto(
    Produto p,
    List<Mercado> mercados,
    Map<String, Mercado> mercadosPorId,
  ) {
    final ordenados = p.precosOrdenados;
    final ultima = p.ultimaAtualizacao;
    final velho =
        ultima != null && DateTime.now().difference(ultima).inDays > 30;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => mostrarEditorProduto(context, p, mercados),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.fixado)
                      const Padding(
                        padding: EdgeInsets.only(right: 6, top: 2),
                        child: Icon(Icons.push_pin,
                            size: 13, color: AppColors.green),
                      ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: p.nome,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          if (p.detalhe.isNotEmpty)
                            TextSpan(
                                text: '   ${p.detalhe}',
                                style: const TextStyle(
                                    color: AppColors.dim, fontSize: 12.5)),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (ultima != null)
                          Text(diaMes(ultima),
                              style: TextStyle(
                                  color: velho
                                      ? AppColors.danger
                                      : AppColors.dim2,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(p.categoria.label.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.dim2,
                                fontSize: 10,
                                letterSpacing: .6,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                if (ordenados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('Sem preço cadastrado — toque para adicionar.',
                        style: TextStyle(color: AppColors.dim2, fontSize: 12.5)),
                  )
                else ...[
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < ordenados.length; i++)
                        _pilulaPreco(
                          mercado: mercadosPorId[ordenados[i].key],
                          preco: ordenados[i].value,
                          menor: i == 0,
                        ),
                    ],
                  ),
                  if (p.economia > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_outlined,
                              size: 15, color: AppColors.green),
                          const SizedBox(width: 6),
                          Text(
                            'economiza ${reais(p.economia)} vs ${mercadosPorId[ordenados[1].key]?.nome ?? '2º mais barato'}',
                            style: const TextStyle(
                                color: AppColors.green,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pilulaPreco({
    required Mercado? mercado,
    required PrecoMercado preco,
    required bool menor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: menor ? AppColors.green.withValues(alpha: 0.5) : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                    color: mercado?.cor ?? AppColors.dim2,
                    shape: BoxShape.circle),
              ),
              Text(mercado?.nome ?? '—',
                  style: const TextStyle(color: AppColors.dim, fontSize: 11)),
              if (menor) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text('MENOR',
                      style: TextStyle(
                          color: AppColors.green,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .5)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(reais(preco.valor),
              style: TextStyle(
                  color: menor ? AppColors.green : AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sell_outlined, size: 52, color: AppColors.dim2),
            const SizedBox(height: 16),
            const Text('Catálogo vazio',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Toque em "+" para cadastrar um produto\ne comparar o preço entre seus mercados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dim, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
