import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/calculadora_screen.dart';
import 'package:lista_app/features/itens/ordenar_categorias_sheet.dart';
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

  /// Assinatura do conjunto de mercados já higienizado (evita repetir a limpeza).
  String? _limpezaFeitaPara;

  /// Backstop: apaga do banco preços de mercados que não existem mais. Roda uma
  /// vez por conjunto de mercados, e só quando há órfão de fato. Nunca com lista
  /// vazia (a guarda em [limparPrecosOrfaos] evita apagar tudo num loading).
  void _talvezLimparOrfaos(List<Mercado> mercados, List<Produto> produtos) {
    if (mercados.isEmpty) return;
    final validos = mercados.map((m) => m.id).toSet();
    final assinatura = (validos.toList()..sort()).join(',');
    if (assinatura == _limpezaFeitaPara) return;
    _limpezaFeitaPara = assinatura;
    final temOrfao = produtos.any((p) =>
        p.precos.keys.any((id) => !validos.contains(id)) ||
        (p.mercadoFixo != null && !validos.contains(p.mercadoFixo)));
    if (!temOrfao) return;
    Future.microtask(
        () => ref.read(produtosRepoProvider).limparPrecosOrfaos(validos));
  }

  @override
  Widget build(BuildContext context) {
    final produtosAsync = ref.watch(produtosProvider);
    final mercados = ref.watch(mercadosProvider).asData?.value ?? [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.sell_rounded, size: 20, color: AppColors.green),
          SizedBox(width: 9),
          Flexible(child: Text('Itens | Comparador', overflow: TextOverflow.ellipsis)),
        ]),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _boxEditar(
                  icon: Icons.storefront_outlined,
                  label: 'Editar mercados',
                  onTap: () => mostrarEditorMercados(context, mercados),
                ),
                const SizedBox(width: 8),
                _boxEditar(
                  icon: Icons.calculate_outlined,
                  label: 'Calculadora',
                  onTap: () => mostrarCalculadora(context),
                ),
                const SizedBox(width: 8),
                _boxEditar(
                  icon: Icons.swap_vert,
                  label: 'Ordenar categorias',
                  onTap: () => mostrarOrdenarCategorias(context),
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
                _talvezLimparOrfaos(mercados, todos);
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
    // Ignora preços de mercados que não existem mais (órfãos): o backstop os
    // apaga do banco, mas aqui o "—" some na hora, antes disso completar.
    final ordenados = p.precosOrdenados
        .where((e) => mercadosPorId.containsKey(e.key))
        .toList();
    final ultima = ordenados.isEmpty
        ? null
        : ordenados
            .map((e) => e.value.data)
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final velho =
        ultima != null && DateTime.now().difference(ultima).inDays > 30;
    // economia = 2º menor - menor, só entre mercados válidos.
    final economia = ordenados.length >= 2
        ? ordenados[1].value.valor - ordenados[0].value.valor
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => mostrarEditorProduto(context, p, mercados),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // nome + detalhe à esquerda; [pino] data categoria à direita
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p.fixado) ...[
                            const Icon(Icons.push_pin,
                                size: 12, color: AppColors.green),
                            const SizedBox(width: 5),
                          ],
                          if (ultima != null) ...[
                            Text(diaMes(ultima),
                                style: TextStyle(
                                    color: velho
                                        ? AppColors.danger
                                        : AppColors.dim2,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 6),
                          ],
                          Text(p.categoria.label.toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.dim2,
                                  fontSize: 10,
                                  letterSpacing: .6,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (p.dedicado)
                  _badgeDedicado(mercadosPorId[p.mercadoFixo], p.fixado)
                else if (ordenados.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text('Sem preço cadastrado — toque para adicionar.',
                        style: TextStyle(color: AppColors.dim2, fontSize: 12.5)),
                  )
                else ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < ordenados.length; i++)
                        _pilulaPreco(
                          mercado: mercadosPorId[ordenados[i].key],
                          preco: ordenados[i].value,
                          menor: i == 0,
                        ),
                    ],
                  ),
                  if (economia > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_outlined,
                              size: 15, color: AppColors.green),
                          const SizedBox(width: 6),
                          Text(
                            'economiza ${reais(economia)} vs ${mercadosPorId[ordenados[1].key]?.nome ?? '2º mais barato'}',
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

  /// Item "de um mercado só": em vez das pílulas de preço, mostra onde comprar.
  Widget _badgeDedicado(Mercado? mercado, bool recorrente) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.storefront, size: 15, color: AppColors.green),
          const SizedBox(width: 7),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
                color: mercado?.cor ?? AppColors.dim2, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Sempre no ${mercado?.nome ?? 'mercado removido'}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.text, fontSize: 12.5),
            ),
          ),
          if (recorrente) ...[
            const SizedBox(width: 8),
            const Icon(Icons.push_pin, size: 12, color: AppColors.green),
            const SizedBox(width: 3),
            const Text('recorrente',
                style: TextStyle(color: AppColors.green, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  /// Pílula de preço numa linha: ● Mercado  R$ x,xx. O mais barato fica
  /// preenchido âmbar (como uma seleção); sem badge "MENOR".
  Widget _pilulaPreco({
    required Mercado? mercado,
    required PrecoMercado preco,
    required bool menor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: menor ? AppColors.green : AppColors.bg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
                color: mercado?.cor ?? AppColors.dim2, shape: BoxShape.circle),
          ),
          Text(mercado?.nome ?? '—',
              style: TextStyle(
                  color: menor ? AppColors.onGreen : AppColors.dim,
                  fontSize: 11.5)),
          const SizedBox(width: 8),
          Text(reais(preco.valor),
              style: TextStyle(
                  color: menor ? AppColors.onGreen : AppColors.text,
                  fontSize: 13,
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
