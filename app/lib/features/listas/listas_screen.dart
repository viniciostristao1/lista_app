import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/produto_editor_screen.dart';
import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/item_lista.dart';
import 'package:lista_app/models/lista.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/pedido.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/auth_service.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/pedidos_repository.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Mercado "efetivo" de um item na lista: o mercado fixo (dedicado/recorrente)
/// se houver; senão o mais barato (comportamento comparável). Null = sem mercado.
String? _mercadoEfetivo(Produto? p) => p?.mercadoFixo ?? p?.mercadoMaisBarato;

/// A compra atual: lista única. Busca um item cadastrado (aba Itens) e puxa.
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
    await repo.adicionarItem(atual.id,
        produtoId: p.id, nome: p.nome, categoria: p.categoria);
    _buscaCtrl.clear();
    setState(() => _busca = '');
  }

  Future<void> _cadastrarEAdicionar(String nome) async {
    final id = await ref
        .read(produtosRepoProvider)
        .criarProduto(nome: nome, categoria: Categoria.outros);
    final listaRepo = ref.read(listasRepoProvider);
    final atual = await listaRepo.obterOuCriarAtiva();
    await listaRepo.adicionarItem(atual.id,
        produtoId: id, nome: nome, categoria: Categoria.outros);
    _buscaCtrl.clear();
    setState(() => _busca = '');
  }

  void _jaNaLista() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Esse item já está na lista 🙂')),
    );
  }

  Future<void> _removerDaLista(ItemLista it, Produto? p, String listaId) async {
    await ref.read(listasRepoProvider).removerItem(listaId, it.id);
    // Some do catálogo só o lembrete solto (sem preço e sem mercado dedicado);
    // item "de um mercado só" é uma entrada deliberada — não apagar.
    if (p != null && p.precos.isEmpty && !p.dedicado) {
      await ref.read(produtosRepoProvider).excluirProduto(p.id);
    }
  }

  /// Exportar = copiar a lista (• antes de cada item) do mercado escolhido.
  Future<void> _exportar(
    List<ItemLista> itens,
    Map<String, Produto> produtosPorId,
    List<Mercado> mercados,
  ) async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SheetExportar(mercados: mercados),
    );
    if (escolha == null) return;
    final selec = escolha == 'todos' ? null : escolha;
    final incluidos = itens.where((it) {
      if (selec == null) return true;
      return _mercadoEfetivo(produtosPorId[it.produtoId]) == selec;
    }).toList();
    if (incluidos.isEmpty) return;
    final texto = incluidos
        .map((it) => '• ${produtosPorId[it.produtoId]?.nome ?? it.nome}')
        .join('\n');
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lista copiada! 📋 Cole onde quiser.')),
      );
    }
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

    final idsNaLista =
        itens.map((e) => e.produtoId).whereType<String>().toSet();

    final filtro =
        (_filtroMercado != null && mercados.any((m) => m.id == _filtroMercado))
            ? _filtroMercado
            : null;

    bool visivel(ItemLista it) {
      if (filtro == null) return true;
      return _mercadoEfetivo(produtosPorId[it.produtoId]) == filtro;
    }

    final itensVisiveis = itens.where(visivel).toList();
    final removiveis = itensVisiveis
        .where((it) => produtosPorId[it.produtoId]?.fixado != true)
        .toList();

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
            tooltip: 'Copiar lista',
            icon: const Icon(Icons.ios_share, color: AppColors.dim),
            onPressed: () => _exportar(itens, produtosPorId, mercados),
          ),
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
                  ..._resultadosBusca(produtos, idsNaLista)
                else if (itens.isEmpty)
                  _vazio()
                else if (itensVisiveis.isEmpty)
                  _filtroVazio(mercadosPorId[filtro]?.nome)
                else
                  ..._itensAgrupados(itensVisiveis, produtosPorId,
                      mercadosPorId, mercados, atual!),
              ],
            ),
          ),
          if (_busca.isEmpty && removiveis.isNotEmpty)
            _botaoFinalizar(atual!, removiveis, produtosPorId, filtro,
                mercadosPorId[filtro]?.nome),
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
        hintText: 'Pesquise ou adicione aqui',
        hintStyle: const TextStyle(color: AppColors.dim2, fontSize: 14),
        prefixIcon:
            const Icon(Icons.shopping_cart_outlined, color: AppColors.dim, size: 20),
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

  List<Widget> _resultadosBusca(List<Produto> produtos, Set<String> idsNaLista) {
    final q = _busca.trim().toLowerCase();
    final matches =
        produtos.where((p) => p.nomeLower.contains(q)).take(12).toList();
    final exato = produtos.any((p) => p.nomeLower == q);

    return [
      for (final p in matches) _linhaBusca(p, idsNaLista.contains(p.id)),
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

  Widget _linhaBusca(Produto p, bool naLista) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: naLista ? _jaNaLista : () => _adicionarProduto(p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Icon(naLista ? Icons.check_circle : Icons.add_circle_outline,
                    color: naLista ? AppColors.dim2 : AppColors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: p.nome,
                          style: TextStyle(
                              color: naLista ? AppColors.dim : AppColors.text,
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
                if (naLista)
                  const Text('já está na lista',
                      style: TextStyle(color: AppColors.dim2, fontSize: 11.5))
                else if (p.menorPreco != null)
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
    );
  }

  // ---------- economia (destaque, uma linha) ----------

  Widget _cardEconomia(
      double economia, double percent, double estimado, int qtd) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D2128), Color(0xFF171A20)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Economia de ',
                    style: TextStyle(color: AppColors.dim, fontSize: 13)),
                TextSpan(
                    text: reais(economia),
                    style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                if (percent > 0)
                  TextSpan(
                      text: ' (${percent.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
              ])),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total ${reais(estimado)}',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text('$qtd ${qtd == 1 ? 'item' : 'itens'}',
                  style:
                      const TextStyle(color: AppColors.dim2, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- itens da lista ----------

  List<Widget> _itensAgrupados(
    List<ItemLista> itens,
    Map<String, Produto> produtosPorId,
    Map<String, Mercado> mercadosPorId,
    List<Mercado> mercados,
    Lista atual,
  ) {
    final widgets = <Widget>[];
    var primeiro = true;
    for (final cat in Categoria.values) {
      final grupo = itens
          .where((e) =>
              (produtosPorId[e.produtoId]?.categoria ?? e.categoria) == cat)
          .toList();
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
        widgets.add(_itemRow(
            it, produtosPorId[it.produtoId], mercadosPorId, mercados, atual));
      }
    }
    return widgets;
  }

  Widget _itemRow(
    ItemLista it,
    Produto? p,
    Map<String, Mercado> mercadosPorId,
    List<Mercado> mercados,
    Lista atual,
  ) {
    final dedicado = p?.dedicado ?? false;
    final menor =
        p?.precosOrdenados.isNotEmpty == true ? p!.precosOrdenados.first : null;
    final mercadoEfId = p?.mercadoFixo ?? menor?.key;
    final cor = mercadoEfId != null ? mercadosPorId[mercadoEfId]?.cor : null;
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
      onDismissed: (_) => _removerDaLista(it, p, atual.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => ref
            .read(listasRepoProvider)
            .setComprado(atual.id, it.id, !it.comprado),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              _checkbox(it.comprado),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (p?.fixado == true) ...[
                          const Icon(Icons.push_pin,
                              size: 12, color: AppColors.green),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: Text(
                            p?.nome ?? it.nome,
                            style: TextStyle(
                              fontSize: 14.5,
                              color:
                                  it.comprado ? AppColors.dim : AppColors.text,
                              decoration: it.comprado
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: AppColors.dim2,
                            ),
                          ),
                        ),
                      ],
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
              // atalho: abre o editor do item (preços/mercado) sem ir à aba Itens
              if (p != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Editar preços/mercado',
                  icon: const Icon(Icons.sell_outlined,
                      size: 18, color: AppColors.dim),
                  onPressed: () => mostrarEditorProduto(context, p, mercados),
                ),
              const SizedBox(width: 4),
              _stepperQtd(atual.id, it),
              const SizedBox(width: 8),
              if (!dedicado)
                Text(
                  menor == null ? '—' : reais(menor.value.valor),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        menor == null ? FontWeight.w400 : FontWeight.w600,
                    color: menor == null
                        ? AppColors.dim2
                        : (it.comprado ? AppColors.dim : AppColors.text),
                  ),
                ),
              if (cor != null) ...[
                const SizedBox(width: 8),
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

  Widget _stepperQtd(String listaId, ItemLista it) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btnQtd(
          Icons.remove,
          it.quantidade > 1
              ? () => ref
                  .read(listasRepoProvider)
                  .setQuantidade(listaId, it.id, it.quantidade - 1)
              : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 20),
          alignment: Alignment.center,
          child: Text('${it.quantidade}',
              style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
        _btnQtd(
          Icons.add,
          () => ref
              .read(listasRepoProvider)
              .setQuantidade(listaId, it.id, it.quantidade + 1),
        ),
      ],
    );
  }

  Widget _btnQtd(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Icon(icon,
            size: 15, color: onTap == null ? AppColors.dim2 : AppColors.text),
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
                : 'Nenhum item em $mercado ainda.',
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

  (double, double, List<PedidoItem>) _montarPedido(
      List<ItemLista> itens, Map<String, Produto> produtosPorId) {
    var total = 0.0, economia = 0.0;
    final pItens = <PedidoItem>[];
    for (final it in itens) {
      final p = produtosPorId[it.produtoId];
      final menor = p?.menorPreco;
      if (menor != null) total += menor * it.quantidade;
      if (p?.segundoMenorPreco != null) economia += p!.economia * it.quantidade;
      pItens.add(PedidoItem(
        produtoId: it.produtoId,
        nome: p?.nome ?? it.nome,
        categoria: p?.categoria ?? it.categoria,
        quantidade: it.quantidade,
        precoUnit: menor,
      ));
    }
    return (total, economia, pItens);
  }

  Widget _botaoFinalizar(
    Lista atual,
    List<ItemLista> removiveis,
    Map<String, Produto> produtosPorId,
    String? filtroMercadoId,
    String? mercadoNome,
  ) {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            final pedidosRepo = ref.read(pedidosRepoProvider);
            // filtro específico = 1 pedido; "Todos" = separa por mercado mais barato
            final grupos = <String?, List<ItemLista>>{};
            if (filtroMercadoId != null) {
              grupos[filtroMercadoId] = removiveis;
            } else {
              for (final it in removiveis) {
                final mid = _mercadoEfetivo(produtosPorId[it.produtoId]);
                grupos.putIfAbsent(mid, () => []).add(it);
              }
            }
            for (final entry in grupos.entries) {
              final (total, economia, pItens) =
                  _montarPedido(entry.value, produtosPorId);
              await pedidosRepo.criar(
                mercadoId: entry.key,
                total: total,
                economia: economia,
                itens: pItens,
              );
            }
            await ref
                .read(listasRepoProvider)
                .removerItens(atual.id, removiveis.map((e) => e.id).toList());
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Compra finalizada! 🛒 (veja em Pedidos)')),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(mercadoNome == null
              ? 'Finalizar compra'
              : 'Finalizar $mercadoNome'),
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

/// Folha de seleção do mercado para "Copiar lista".
class _SheetExportar extends StatelessWidget {
  const _SheetExportar({required this.mercados});
  final List<Mercado> mercados;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.dim2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Copiar lista de:',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          _opcao(context, 'todos', 'Todos os itens', null),
          for (final m in mercados) _opcao(context, m.id, m.nome, m.cor),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _opcao(BuildContext context, String valor, String label, Color? cor) {
    return InkWell(
      onTap: () => Navigator.pop(context, valor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: cor ?? AppColors.dim2, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: AppColors.text, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
