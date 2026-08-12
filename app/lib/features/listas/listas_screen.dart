import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/produto_editor_screen.dart';
import 'package:lista_app/l10n/strings.dart';
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
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/theme/palette.dart';
import 'package:lista_app/util/format.dart';

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
  bool _filtroSemMercado = false; // filtro "Sem mercado" (itens soltos)

  /// Itens cujo preço está revelado (usuário tocou no "$"). Por padrão o preço
  /// fica escondido atrás do ícone, deixando a coluna alinhada.
  final Set<String> _precoVisivel = {};

  // read (não watch): usado no build e em callbacks; a reatividade ao trocar de
  // idioma vem do ref.watch(stringsProvider) no topo do build.
  AppStrings get _t => ref.read(stringsProvider);

  /// Mercado "efetivo" do item: mercado fixo → mais barato. Null = solto
  /// (sem mercado) → cai no filtro "Sem mercado".
  String? _mercadoEfetivo(Produto? p) => p?.mercadoFixo ?? p?.mercadoMaisBarato;

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

  // Cadastra um item NOVO já dedicado a um mercado (sem preço) e adiciona.
  Future<void> _cadastrarEmMercado(String nome, String mercadoId) async {
    final id = await ref.read(produtosRepoProvider).criarProduto(
        nome: nome, categoria: Categoria.outros, mercadoFixo: mercadoId);
    final listaRepo = ref.read(listasRepoProvider);
    final atual = await listaRepo.obterOuCriarAtiva();
    await listaRepo.adicionarItem(atual.id,
        produtoId: id, nome: nome, categoria: Categoria.outros);
    _buscaCtrl.clear();
    setState(() => _busca = '');
  }

  // Mercados com o ⭐ preferido primeiro.
  List<Mercado> _mercadosOrdenados(List<Mercado> mercados) => [
        ...mercados.where((m) => m.preferencia),
        ...mercados.where((m) => !m.preferencia),
      ];

  // Enter no teclado: adiciona o item digitado. Se já existe no catálogo, puxa
  // esse; senão, cadastra e adiciona. (Item sem preço vai pro preferido/Todos.)
  Future<void> _submeterBusca(
      List<Produto> produtos, Set<String> idsNaLista) async {
    final nome = _buscaCtrl.text.trim();
    if (nome.isEmpty) return;
    final q = nome.toLowerCase();
    Produto? exato;
    for (final p in produtos) {
      if (p.nomeLower == q) {
        exato = p;
        break;
      }
    }
    if (exato != null) {
      if (idsNaLista.contains(exato.id)) {
        _jaNaLista();
        _buscaCtrl.clear();
        setState(() => _busca = '');
      } else {
        await _adicionarProduto(exato);
      }
    } else {
      await _cadastrarEAdicionar(nome);
    }
  }

  void _jaNaLista() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t.itemJaNaLista)),
    );
  }

  Future<void> _removerComDesfazer(
      ItemLista it, Produto? p, String listaId) async {
    final listaRepo = ref.read(listasRepoProvider);
    final produtoRepo = ref.read(produtosRepoProvider);
    // Some do catálogo só o lembrete solto (sem preço e sem mercado dedicado).
    final apagaProduto = p != null && p.precos.isEmpty && !p.dedicado;
    final nome = p?.nome ?? it.nome;
    final categoria = p?.categoria ?? it.categoria;

    await listaRepo.removerItem(listaId, it.id);
    if (apagaProduto) await produtoRepo.excluirProduto(p.id);

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final ctrl = messenger.showSnackBar(SnackBar(
      content: Text(_t.itemRemovido(nome)),
      duration: const Duration(seconds: 30), // fallback; fechamos manualmente
      action: SnackBarAction(
        label: _t.desfazer,
        textColor: AppColors.green,
        onPressed: () async {
          var produtoId = it.produtoId;
          // se o produto foi apagado (lembrete solto), recria pra religar
          if (apagaProduto) {
            produtoId =
                await produtoRepo.criarProduto(nome: nome, categoria: categoria);
          }
          await listaRepo.adicionarItem(listaId,
              produtoId: produtoId,
              nome: nome,
              categoria: categoria,
              quantidade: it.quantidade,
              preco: it.preco,
              mercadoId: it.mercadoId);
        },
      ),
    ));
    // Fecha em ~3s de forma confiável: o timer interno do SnackBar não dispara
    // quando as animações do sistema estão desativadas (bug conhecido do Flutter).
    Timer(const Duration(seconds: 3), () {
      try {
        ctrl.close();
      } catch (_) {}
    });
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
      builder: (_) => _SheetExportar(mercados: mercados, t: _t),
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
        SnackBar(content: Text(_t.listaCopiada)),
      );
    }
  }

  void _mostrarConfig() {
    final t = _t;
    final atual = ref.read(fontScaleProvider);
    final en = ref.read(idiomaEnProvider);
    final temaAtual = ref.read(temaProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _tituloConfig(t.tema),
              for (final tm in Tema.values) _opcaoTema(tm, temaAtual),
              Divider(color: AppColors.lineStrong, height: 20),
              _tituloConfig(t.idioma),
              _opcaoIdioma('Português', false, en),
              _opcaoIdioma('English', true, en),
              Divider(color: AppColors.lineStrong, height: 20),
              _tituloConfig(t.tamanhoDaFonte, sub: t.valeAppInteiro),
              _opcaoFonte(t.fonteMenor, 0.93, atual),
              _opcaoFonte(t.fonteNormal, 1.035, atual),
              _opcaoFonte(t.fonteMaior, 1.22, atual),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcaoTema(Tema tm, Tema atual) {
    final sel = tm == atual;
    final p = paletteDoTema(tm);
    return ListTile(
      onTap: () {
        ref.read(temaProvider.notifier).definir(tm);
        Navigator.pop(context);
      },
      leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
          color: sel ? AppColors.green : AppColors.dim2),
      // prévia do tema: fundo + acento do tema
      trailing: Container(
        width: 46,
        height: 26,
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: p.green, shape: BoxShape.circle),
          ),
        ),
      ),
      title: Text(_t.nomeTema(tm),
          style: TextStyle(
              color: sel ? AppColors.green : AppColors.text,
              fontSize: 15,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
    );
  }

  Widget _tituloConfig(String titulo, {String? sub}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, sub == null ? 6 : 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            if (sub != null)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 6),
                child: Text(sub,
                    style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _opcaoIdioma(String label, bool valor, bool atual) {
    final sel = valor == atual;
    return ListTile(
      onTap: () {
        ref.read(idiomaEnProvider.notifier).definir(valor);
        Navigator.pop(context);
      },
      leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
          color: sel ? AppColors.green : AppColors.dim2),
      title: Text(label,
          style: TextStyle(
              color: sel ? AppColors.green : AppColors.text,
              fontSize: 15,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
    );
  }

  Widget _opcaoFonte(String label, double v, double atual) {
    final sel = (atual - v).abs() < 0.001;
    return ListTile(
      onTap: () {
        ref.read(fontScaleProvider.notifier).definir(v);
        Navigator.pop(context);
      },
      leading: Icon(sel ? Icons.radio_button_checked : Icons.radio_button_off,
          color: sel ? AppColors.green : AppColors.dim2),
      title: Text(label,
          style: TextStyle(
              color: sel ? AppColors.green : AppColors.text,
              fontSize: 15 * v,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ativas = ref.watch(listasAtivasProvider).asData?.value ?? const [];
    final atual = ativas.isEmpty ? null : ativas.first;
    final produtos = ref.watch(produtosProvider).asData?.value ?? const [];
    final produtosPorId = {for (final p in produtos) p.id: p};
    final mercados = ref.watch(mercadosProvider).asData?.value ?? const [];
    final ordemCategorias = ref.watch(categoriaOrdemProvider);
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
      final ef = _mercadoEfetivo(produtosPorId[it.produtoId]);
      if (_filtroSemMercado) return ef == null;
      if (filtro == null) return true;
      return ef == filtro;
    }

    final itensVisiveis = itens.where(visivel).toList();
    // Finalizar processa só os itens MARCADOS (comprados); os não marcados
    // continuam na lista (não deu pra comprar). Recorrente (fixado) nunca sai.
    final removiveis = itensVisiveis
        .where((it) =>
            it.comprado && produtosPorId[it.produtoId]?.fixado != true)
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
    final t = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.checklist_rounded, size: 21, color: AppColors.green),
          const SizedBox(width: 9),
          Text(t.minhaLista),
        ]),
        actions: [
          IconButton(
            tooltip: t.configuracoes,
            icon: Icon(Icons.settings_outlined, color: AppColors.dim),
            onPressed: _mostrarConfig,
          ),
          IconButton(
            tooltip: t.copiarLista,
            icon: Icon(Icons.ios_share, color: AppColors.dim),
            onPressed: () => _exportar(itens, produtosPorId, mercados),
          ),
          IconButton(
            tooltip: t.sair,
            icon: Icon(Icons.logout_rounded, color: AppColors.dim),
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
                _barraFiltro(mercados, filtro, itens, produtosPorId),
                const SizedBox(height: 12),
                _cardEconomia(economia, percent, estimadoVis, itensVisiveis.length),
                const SizedBox(height: 12),
                _campoBusca(produtos, idsNaLista),
                const SizedBox(height: 8),
                if (_busca.isNotEmpty)
                  ..._resultadosBusca(produtos, idsNaLista, mercados)
                else if (itens.isEmpty)
                  _vazio()
                else if (itensVisiveis.isEmpty)
                  _filtroVazio(mercadosPorId[filtro]?.nome)
                else
                  ..._itensAgrupados(itensVisiveis, produtosPorId,
                      mercadosPorId, mercados, ordemCategorias, atual!),
              ],
            ),
          ),
          // Some com o teclado aberto (ex.: buscando) — não flutua sobre ele.
          if (MediaQuery.of(context).viewInsets.bottom == 0 &&
              _busca.isEmpty &&
              removiveis.isNotEmpty)
            _botaoFinalizar(atual!, removiveis, produtosPorId, filtro,
                mercadosPorId[filtro]?.nome),
        ],
      ),
    );
  }

  // ---------- barra de filtro por mercado ----------

  Widget _barraFiltro(List<Mercado> mercados, String? filtro,
      List<ItemLista> itens, Map<String, Produto> produtosPorId) {
    if (mercados.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(_t.cadastreMercadosNaAbaItens,
            style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
      );
    }
    // quantos itens caem em cada mercado (pelo mercado efetivo) + total.
    final contagem = <String?, int>{};
    for (final it in itens) {
      final m = _mercadoEfetivo(produtosPorId[it.produtoId]);
      contagem[m] = (contagem[m] ?? 0) + 1;
    }
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chipFiltro(
            label: _t.todos,
            count: itens.length,
            selecionado: filtro == null && !_filtroSemMercado,
            onTap: () => setState(() {
              _filtroMercado = null;
              _filtroSemMercado = false;
            }),
          ),
          // ⭐ mercado principal — em destaque, logo ao lado de "Todos"
          for (final m in mercados.where((m) => m.preferencia))
            _chipFiltro(
              label: m.nome,
              cor: m.cor,
              estrela: true,
              count: contagem[m.id] ?? 0,
              selecionado: !_filtroSemMercado && filtro == m.id,
              onTap: () => setState(() {
                _filtroMercado = m.id;
                _filtroSemMercado = false;
              }),
            ),
          // itens soltos (sem mercado) — pra rever e ajustar
          _chipFiltro(
            label: _t.semMercado,
            count: contagem[null] ?? 0,
            selecionado: _filtroSemMercado,
            onTap: () => setState(() {
              _filtroSemMercado = true;
              _filtroMercado = null;
            }),
          ),
          for (final m in mercados.where((m) => !m.preferencia))
            _chipFiltro(
              label: m.nome,
              cor: m.cor,
              count: contagem[m.id] ?? 0,
              selecionado: !_filtroSemMercado && filtro == m.id,
              onTap: () => setState(() {
                _filtroMercado = m.id;
                _filtroSemMercado = false;
              }),
            ),
        ],
      ),
    );
  }

  Widget _chipFiltro({
    required String label,
    required int count,
    Color? cor,
    bool estrela = false,
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
            color: selecionado ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (estrela) ...[
                Icon(Icons.star,
                    size: 12,
                    color:
                        selecionado ? AppColors.onGreen : AppColors.green),
                const SizedBox(width: 5),
              ],
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
                    color: selecionado ? AppColors.onGreen : AppColors.dim,
                    fontSize: 12.5,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                  )),
              const SizedBox(width: 5),
              // contagem discreta: (2), (0)…
              Text('($count)',
                  style: TextStyle(
                    color: selecionado
                        ? AppColors.onGreen.withValues(alpha: 0.7)
                        : AppColors.dim2,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- busca / adicionar ----------

  Widget _campoBusca(List<Produto> produtos, Set<String> idsNaLista) {
    return TextField(
      controller: _buscaCtrl,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onChanged: (v) => setState(() => _busca = v),
      onSubmitted: (_) => _submeterBusca(produtos, idsNaLista),
      style: TextStyle(color: AppColors.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: _t.pesquiseOuAdicione,
        hintStyle: TextStyle(color: AppColors.dim2, fontSize: 14),
        prefixIcon:
            Icon(Icons.shopping_cart_outlined, color: AppColors.dim, size: 20),
        suffixIcon: _busca.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: AppColors.dim, size: 18),
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
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.green),
        ),
      ),
    );
  }

  List<Widget> _resultadosBusca(
      List<Produto> produtos, Set<String> idsNaLista, List<Mercado> mercados) {
    final q = _busca.trim().toLowerCase();
    final matches =
        produtos.where((p) => p.nomeLower.contains(q)).take(12).toList();
    final exato = produtos.any((p) => p.nomeLower == q);

    return [
      for (final p in matches) _linhaBusca(p, idsNaLista.contains(p.id)),
      // Item novo (não existe ainda): cadastrar solto OU já num mercado.
      if (q.isNotEmpty && !exato) ...[
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: TextButton.icon(
            onPressed: () => _cadastrarEAdicionar(_buscaCtrl.text.trim()),
            icon: Icon(Icons.add, size: 18, color: AppColors.green),
            label: Text(_t.cadastrarEAdicionar(_buscaCtrl.text.trim()),
                style: TextStyle(color: AppColors.green)),
          ),
        ),
        if (mercados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_t.ouJaNumMercado,
                    style: TextStyle(color: AppColors.dim, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _mercadosOrdenados(mercados))
                      _chipCadastrarMercado(m),
                  ],
                ),
              ],
            ),
          ),
      ],
      if (matches.isEmpty && (q.isEmpty || exato))
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Center(
            child: Text(_t.nenhumItemEncontrado,
                style: TextStyle(color: AppColors.dim2)),
          ),
        ),
    ];
  }

  Widget _chipCadastrarMercado(Mercado m) {
    return GestureDetector(
      onTap: () => _cadastrarEmMercado(_buscaCtrl.text.trim(), m.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: m.cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(m.nome,
                style: TextStyle(color: AppColors.text, fontSize: 12.5)),
            if (m.preferencia) ...[
              const SizedBox(width: 5),
              Icon(Icons.star, size: 12, color: AppColors.green),
            ],
          ],
        ),
      ),
    );
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
                            style: TextStyle(
                                color: AppColors.dim2, fontSize: 12)),
                    ]),
                  ),
                ),
                if (naLista)
                  Text(_t.jaEstaNaListaCurto,
                      style: TextStyle(color: AppColors.dim2, fontSize: 11.5))
                else if (p.menorPreco != null)
                  Text(reais(p.menorPreco!),
                      style: TextStyle(
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
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardGrad1, AppColors.cardGrad2],
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
                TextSpan(
                    text: _t.economiaDe,
                    style: TextStyle(color: AppColors.dim, fontSize: 13)),
                TextSpan(
                    text: reais(economia),
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                if (percent > 0)
                  TextSpan(
                      text: ' (${percent.toStringAsFixed(0)}%)',
                      style: TextStyle(
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
              Text(_t.total(reais(estimado)),
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(_t.nItens(qtd),
                  style:
                      TextStyle(color: AppColors.dim2, fontSize: 11.5)),
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
    List<Categoria> ordemCategorias,
    Lista atual,
  ) {
    final widgets = <Widget>[];
    var primeiro = true;
    String nomeDe(ItemLista e) =>
        (produtosPorId[e.produtoId]?.nome ?? e.nome).toLowerCase();
    for (final cat in ordemCategorias) {
      final grupo = itens
          .where((e) =>
              (produtosPorId[e.produtoId]?.categoria ?? e.categoria) == cat)
          .toList()
        // #5: ordem alfabética dentro da categoria
        ..sort((a, b) => nomeDe(a).compareTo(nomeDe(b)));
      if (grupo.isEmpty) continue;
      widgets.add(Padding(
        padding: EdgeInsets.fromLTRB(2, primeiro ? 0 : 3, 2, 0),
        child: Text(_t.categoria_(cat).toUpperCase(),
            style: TextStyle(
                color: AppColors.dim2,
                fontSize: 11,
                height: 1.0,
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
        color: AppColors.danger.withValues(alpha: 0.16),
        child: Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) => _removerComDesfazer(it, p, atual.id),
      child: InkWell(
        onTap: () => ref
            .read(listasRepoProvider)
            .setComprado(atual.id, it.id, !it.comprado),
        // FLAT: item sem caixinha — fundo do app, separado por linha fina embaixo
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.lineStrong)),
          ),
          child: Row(
            children: [
              _checkbox(it.comprado),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.nome ?? it.nome,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: it.comprado ? AppColors.dim : AppColors.text,
                        decoration: it.comprado
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: AppColors.dim2,
                      ),
                    ),
                    if (velho)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.danger),
                          const SizedBox(width: 4),
                          Text(_t.precoDesatualizado,
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 11)),
                        ]),
                      ),
                  ],
                ),
              ),
              // #5: pino de "recorrente" depois da descrição, antes do editar
              if (p?.fixado == true) ...[
                Icon(Icons.push_pin, size: 13, color: AppColors.green),
                const SizedBox(width: 4),
              ],
              // atalho: abre o editor do item (preços/mercado) sem ir à aba Itens
              if (p != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 22),
                  tooltip: _t.editarPrecosMercado,
                  icon: Icon(Icons.sell_outlined,
                      size: 18, color: AppColors.dim),
                  onPressed: () => mostrarEditorProduto(context, p, mercados),
                ),
              const SizedBox(width: 4),
              _stepperQtd(atual.id, it),
              const SizedBox(width: 3),
              // Slot de preço enxuto: SEMPRE um "$" estreito (deixa espaço pro
              // nome). Tocar expande e revela o preço (item comparado) ou o
              // nome do mercado (item de um mercado só). "+" e bolinha colados.
              _slotPreco(it, dedicado, menor, mercadoEfId, mercadosPorId),
              const SizedBox(width: 3),
              // bolinha do mercado — slot fixo p/ alinhar mesmo quando não há cor
              SizedBox(
                width: 9,
                height: 9,
                child: cor == null
                    ? null
                    : DecoratedBox(
                        decoration: BoxDecoration(
                            color: cor, shape: BoxShape.circle)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Slot de preço enxuto: por padrão SEMPRE um "$" estreito (deixa mais espaço
  // pro nome do item). Ao tocar, expande e revela o texto — o preço (item
  // comparado) ou o nome do mercado (item de um mercado só). Toca de novo esconde.
  Widget _slotPreco(
    ItemLista it,
    bool dedicado,
    MapEntry<String, PrecoMercado>? menor,
    String? mercadoEfId,
    Map<String, Mercado> mercadosPorId,
  ) {
    // O que o "$" revela: o nome do mercado (dedicado) ou o preço (comparado).
    final String? revelado = dedicado
        ? mercadosPorId[mercadoEfId]?.nome
        : (menor == null ? null : reais(menor.value.valor));

    // Nada cadastrado ainda: "$" apagado, só avisa (não expande).
    if (revelado == null) {
      return _botaoDollar(
        cor: AppColors.dim2,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t.itemSemPreco)),
        ),
      );
    }

    // Revelado: expande e "empurra" o nome (Expanded) pra caber o texto.
    if (_precoVisivel.contains(it.id)) {
      return GestureDetector(
        onTap: () => setState(() => _precoVisivel.remove(it.id)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            revelado,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dedicado ? 12.5 : 14,
              fontWeight: dedicado ? FontWeight.w500 : FontWeight.w600,
              color: it.comprado ? AppColors.dim : AppColors.text,
            ),
          ),
        ),
      );
    }

    // Colapsado: "$" estreito.
    return _botaoDollar(
      cor: it.comprado ? AppColors.dim2 : AppColors.dim,
      onTap: () => setState(() => _precoVisivel.add(it.id)),
    );
  }

  Widget _botaoDollar({required Color cor, required VoidCallback onTap}) {
    // Sem IconButton de propósito: ele reserva a área de toque padrão (~40px de
    // largura) mesmo com minWidth pequeno. Aqui a área é uma SizedBox estreita
    // de verdade (16px), com o toque garantido pela altura. Assim o "+" e a
    // bolinha do mercado ficam colados, com só o "$" no meio.
    return Tooltip(
      message: _t.verPrecoMercado,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 16,
          height: 30,
          child: Center(
            child: Icon(Icons.attach_money, size: 15, color: cor),
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
              style: TextStyle(
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
        width: 22,
        height: 22,
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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: marcado ? AppColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: marcado ? AppColors.green : AppColors.dim2,
          width: 2,
        ),
      ),
      child: marcado
          ? Icon(Icons.check, size: 15, color: AppColors.onGreen)
          : null,
    );
  }

  Widget _filtroVazio(String? mercado) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: 40, color: AppColors.dim2),
          const SizedBox(height: 12),
          Text(
            mercado == null ? _t.nadaAqui : _t.nenhumItemEmMercado(mercado),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.dim, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search, size: 44, color: AppColors.dim2),
          const SizedBox(height: 14),
          Text(_t.suaListaVazia,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_t.useBuscaPuxarItem,
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
                SnackBar(content: Text(_t.compraFinalizada)),
              );
            }
          },
          icon: const Icon(Icons.check_circle_outline, size: 20),
          label: Text(mercadoNome == null
              ? _t.finalizarCompra
              : _t.finalizarMercado(mercadoNome)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.onGreen,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

/// Folha de seleção do mercado para "Copiar lista".
class _SheetExportar extends StatelessWidget {
  const _SheetExportar({required this.mercados, required this.t});
  final List<Mercado> mercados;
  final AppStrings t;

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
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(t.copiarListaDe,
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          _opcao(context, 'todos', t.todosOsItens, null),
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
                style: TextStyle(color: AppColors.text, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }
}
