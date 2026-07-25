import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/item_lista.dart';
import 'package:lista_app/models/lista.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/auth_service.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// A compra atual: lista única. Busca um item cadastrado (aba Itens) e puxa.
/// A barra de mercados no topo filtra a lista pelo mercado mais barato.
/// (Editar mercados agora fica na aba Itens.)
class ListasScreen extends ConsumerStatefulWidget {
  const ListasScreen({super.key});

  @override
  ConsumerState<ListasScreen> createState() => _ListasScreenState();
}

class _ListasScreenState extends ConsumerState<ListasScreen> {
  final _buscaCtrl = TextEditingController();
  String _busca = '';
  String? _filtroMercado; // null = "Todos"

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _adicionarProduto(Produto p) async {
    final repo = ref.read(listasRepoProvider);
    final atual = await repo.obterOuCriarAtiva();
    await repo.adicionarItem(
      atual.id,
      produtoId: p.id,
      nome: p.nome,
      categoria: p.categoria,
    );
    _buscaCtrl.clear();
    setState(() => _busca = '');
  }

  Future<void> _cadastrarEAdicionar(String nome) async {
    final id = await ref
        .read(produtosRepoProvider)
        .criarProduto(nome: nome, categoria: Categoria.outros);
    final listaRepo = ref.read(listasRepoProvider);
    final atual = await listaRepo.obterOuCriarAtiva();
    await listaRepo.adicionarItem(
      atual.id,
      produtoId: id,
      nome: nome,
      categoria: Categoria.outros,
    );
    _buscaCtrl.clear();
    setState(() => _busca = '');
  }

  @override
  Widget build(BuildContext context) {
    final ativas = ref.watch(listasAtivasProvider).asData?.value ?? const [];
    final atual = ativas.isEmpty ? null : ativas.first;
    final produtos = ref.watch(produtosProvider).asData?.value ?? const [];
    final produtosPorId = {for (final p in produtos) p.id: p};
    final mercados = ref.watch(mercadosProvider).asData?.value ?? const [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    final itens = atual == null
        ? const <ItemLista>[]
        : (ref.watch(itensProvider(atual.id)).asData?.value ??
            const <ItemLista>[]);

    final filtro =
        (_filtroMercado != null && mercados.any((m) => m.id == _filtroMercado))
            ? _filtroMercado
            : null;

    bool visivel(ItemLista it) {
      if (filtro == null) return true;
      return produtosPorId[it.produtoId]?.mercadoMaisBarato == filtro;
    }

    final itensVisiveis = itens.where(visivel).toList();

    var economia = 0.0, baseSegundo = 0.0, estimadoVis = 0.0;
    for (final it in itensVisiveis) {
      final p = produtosPorId[it.produtoId];
      if (p == null) continue;
      final menor = p.menorPreco;
      if (menor != null) estimadoVis += menor * it.quantidade;
      final segundo = p.segundoMenorPreco;
      if (segundo != null) {
        economia += p.economia * it.quantidade;
        baseSegundo += segundo * it.quantidade;
      }
    }
    final percent = baseSegundo > 0 ? economia / baseSegundo * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha lista'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded, color: AppColors.dim),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              children: [
                _barraFiltro(mercados, filtro),
                const SizedBox(height: 12),
                _cardEconomia(economia, percent, estimadoVis, itensVisiveis.length),
                const SizedBox(height: 12),
                _campoBusca(),
                const SizedBox(height: 8),
                if (_busca.isNotEmpty)
                  ..._resultadosBusca(produtos)
                else if (itens.isEmpty)
                  _vazio()
                else if (itensVisiveis.isEmpty)
                  _filtroVazio(mercadosPorId[filtro]?.nome)
                else
                  ..._itensAgrupados(
                      itensVisiveis, produtosPorId, mercadosPorId, atual!),
              ],
            ),
          ),
          if (_busca.isEmpty && itensVisiveis.isNotEmpty)
            _botaoFinalizar(atual!, itensVisiveis, mercadosPorId[filtro]?.nome),
        ],
      ),
    );
  }

  // ---------- barra de filtro por mercado ----------

  Widget _barraFiltro(List<Mercado> mercados, String? filtro) {
    if (mercados.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line),
        ),
        child: const Text('Cadastre seus mercados na aba Itens (Editar mercados).',
            style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
      );
    }
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chipFiltro(
            label: 'Todos',
            selecionado: filtro == null,
            onTap: () => setState(() => _filtroMercado = null),
          ),
          for (final m in mercados)
            _chipFiltro(
              label: m.nome,
              cor: m.cor,
              selecionado: filtro == m.id,
              onTap: () => setState(() => _filtroMercado = m.id),
            ),
        ],
      ),
    );
  }

  Widget _chipFiltro({
    required String label,
    Color? cor,
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selecionado
                ? AppColors.green.withValues(alpha: 0.14)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selecionado ? AppColors.green : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cor != null) ...[
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: TextStyle(
                    color: selecionado ? AppColors.green : AppColors.dim,
                    fontSize: 12.5,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- busca / adicionar ----------

  Widget _campoBusca() {
    return TextField(
      controller: _buscaCtrl,
      onChanged: (v) => setState(() => _busca = v),
      style: const TextStyle(color: AppColors.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'Buscar item cadastrado para adicionar…',
        hintStyle: const TextStyle(color: AppColors.dim2, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: AppColors.dim, size: 20),
        suffixIcon: _busca.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, color: AppColors.dim, size: 18),
                onPressed: () {
                  _buscaCtrl.clear();
                  setState(() => _busca = '');
                },
              ),
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green),
        ),
      ),
    );
  }

  List<Widget> _resultadosBusca(List<Produto> produtos) {
    final q = _busca.trim().toLowerCase();
    final matches =
        produtos.where((p) => p.nomeLower.contains(q)).take(12).toList();
    final exato = produtos.any((p) => p.nomeLower == q);

    return [
      for (final p in matches)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _adicionarProduto(p),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_circle_outline,
                        color: AppColors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: p.nome,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500)),
                          if (p.detalhe.isNotEmpty)
                            TextSpan(
                                text: '  ${p.detalhe}',
                                style: const TextStyle(
                                    color: AppColors.dim2, fontSize: 12)),
                        ]),
                      ),
                    ),
                    if (p.menorPreco != null)
                      Text(reais(p.menorPreco!),
                          style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      if (q.isNotEmpty && !exato)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: TextButton.icon(
            onPressed: () => _cadastrarEAdicionar(_buscaCtrl.text.trim()),
            icon: const Icon(Icons.add, size: 18, color: AppColors.green),
            label: Text('Cadastrar "${_buscaCtrl.text.trim()}" e adicionar',
                style: const TextStyle(color: AppColors.green)),
          ),
        ),
      if (matches.isEmpty && (q.isEmpty || exato))
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Center(
            child: Text('Nenhum item encontrado.',
                style: TextStyle(color: AppColors.dim2)),
          ),
        ),
    ];
  }

  // ---------- economia (destaque, compacto) ----------

  Widget _cardEconomia(
      double economia, double percent, double estimado, int qtd) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text('Economia pegando os mais baratos',
              style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(reais(economia),
                  style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 23,
                      fontWeight: FontWeight.w700)),
              if (percent > 0) ...[
                const SizedBox(width: 6),
                Text('(${percent.toStringAsFixed(0)}%)',
                    style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  economia > 0
                      ? 'vs a 2ª opção mais barata'
                      : 'cadastre em 2+ mercados para calcular',
                  style: const TextStyle(color: AppColors.dim2, fontSize: 11.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text('Estimado ${reais(estimado)} · $qtd ${qtd == 1 ? 'item' : 'itens'}',
              style: const TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------- itens da lista ----------

  List<Widget> _itensAgrupados(
    List<ItemLista> itens,
    Map<String, Produto> produtosPorId,
    Map<String, Mercado> mercadosPorId,
    Lista atual,
  ) {
    final widgets = <Widget>[];
    var primeiro = true;
    for (final cat in Categoria.values) {
      final grupo = itens.where((e) => e.categoria == cat).toList();
      if (grupo.isEmpty) continue;
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(2, primeiro ? 10 : 6, 2, 6),
        child: Text(cat.label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.dim2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
      ));
      primeiro = false;
      for (final it in grupo) {
        widgets
            .add(_itemRow(it, produtosPorId[it.produtoId], mercadosPorId, atual));
      }
    }
    return widgets;
  }

  Widget _itemRow(
    ItemLista it,
    Produto? p,
    Map<String, Mercado> mercadosPorId,
    Lista atual,
  ) {
    final menor =
        p?.precosOrdenados.isNotEmpty == true ? p!.precosOrdenados.first : null;
    final cor = menor != null ? mercadosPorId[menor.key]?.cor : null;
    final velho = menor?.value.desatualizado ?? false;

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
          ref.read(listasRepoProvider).removerItem(atual.id, it.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref
            .read(listasRepoProvider)
            .setComprado(atual.id, it.id, !it.comprado),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.nome,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: it.comprado ? AppColors.dim : AppColors.text,
                        decoration:
                            it.comprado ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.dim2,
                      ),
                    ),
                    if (velho)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.danger),
                          SizedBox(width: 4),
                          Text('preço desatualizado',
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ),
              Text(
                menor == null ? '—' : reais(menor.value.valor),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: menor == null ? FontWeight.w400 : FontWeight.w600,
                  color: menor == null
                      ? AppColors.dim2
                      : (it.comprado ? AppColors.dim : AppColors.text),
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

  Widget _filtroVazio(String? mercado) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_off_outlined,
              size: 40, color: AppColors.dim2),
          const SizedBox(height: 12),
          Text(
            mercado == null
                ? 'Nada aqui.'
                : 'Nenhum item é mais barato em $mercado.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search, size: 44, color: AppColors.dim2),
          SizedBox(height: 14),
          Text('Sua lista está vazia',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Use a busca acima para puxar um item cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _botaoFinalizar(
      Lista atual, List<ItemLista> visiveis, String? mercadoNome) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            await ref
                .read(listasRepoProvider)
                .removerItens(atual.id, visiveis.map((e) => e.id).toList());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(mercadoNome == null
                        ? 'Compra finalizada! 🛒'
                        : 'Itens de $mercadoNome concluídos ✓')),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(
              mercadoNome == null ? 'Finalizar compra' : 'Finalizar $mercadoNome'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green.withValues(alpha: 0.14),
            foregroundColor: AppColors.green,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}
