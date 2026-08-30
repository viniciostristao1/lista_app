import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/l10n/strings.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/pedido.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/pedidos_repository.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Histórico de compras. Filtro por ano/mês (topo) + por mercado (chips).
/// As somas do resumo respeitam o ano/mês/mercado selecionados.
class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  String? _filtroMercado; // null = "Todos"
  late int _ano;
  late int _mes;
  final _buscaCtrl = TextEditingController();
  String _busca = '';

  AppStrings get _t => ref.read(stringsProvider);

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _ano = now.year;
    _mes = now.month;
  }

  Future<void> _desfazer(Pedido pe) async {
    final listaRepo = ref.read(listasRepoProvider);
    final atual = await listaRepo.obterOuCriarAtiva();
    for (final it in pe.itens) {
      await listaRepo.adicionarItem(
        atual.id,
        produtoId: it.produtoId,
        nome: it.nome,
        categoria: it.categoria,
        quantidade: it.quantidade,
      );
    }
    await ref.read(pedidosRepoProvider).excluir(pe.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.pedidoDesfeito)),
      );
    }
  }

  Future<void> _excluir(Pedido pe) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_t.excluirPedidoTitulo),
        content: Text(_t.excluirPedidoMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(_t.cancelar)),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(_t.excluir,
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(pedidosRepoProvider).excluir(pe.id);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.pedidoExcluido)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final pedidos = ref.watch(pedidosProvider).asData?.value ?? const [];
    final mercados = ref.watch(mercadosProvider).asData?.value ?? const [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    final filtroMercado =
        (_filtroMercado != null && mercados.any((m) => m.id == _filtroMercado))
            ? _filtroMercado
            : null;

    // anos disponíveis (dos pedidos) + o ano atual
    final anos = <int>{
      DateTime.now().year,
      for (final pe in pedidos)
        if (pe.data != null) pe.data!.year,
    }.toList()
      ..sort((a, b) => b.compareTo(a));

    final filtrados = pedidos.where((pe) {
      final d = pe.data;
      if (d == null) return false;
      if (d.year != _ano || d.month != _mes) return false;
      if (filtroMercado != null && pe.mercadoId != filtroMercado) return false;
      return true;
    }).toList();

    var econ = 0.0, total = 0.0;
    for (final pe in filtrados) {
      econ += pe.economia;
      total += pe.total;
    }

    final buscaLower = normalizarBusca(_busca.trim());
    final temBusca = buscaLower.isNotEmpty;
    final filtradosBusca = temBusca
        ? filtrados.where((pe) => pe.itens.any((it) => normalizarBusca(it.nome).contains(buscaLower))).toList()
        : filtrados;
    double totalBusca = 0;
    int qtdBusca = 0;
    int qtdPedidosBusca = filtradosBusca.length;
    if (temBusca) {
      for (final pe in filtradosBusca) {
        for (final it in pe.itens) {
          if (normalizarBusca(it.nome).contains(buscaLower)) {
            totalBusca += (it.precoUnit ?? 0) * it.quantidade;
            qtdBusca += it.quantidade;
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bar_chart_rounded, size: 21, color: AppColors.green),
          const SizedBox(width: 9),
          Text(t.abaPedidos),
        ]),
        actions: [_dropdownAno(anos)],
      ),
      body: Column(
        children: [
          _barraMeses(),
          if (mercados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
              child: _barraMercados(mercados, filtroMercado),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              controller: _buscaCtrl,
              onChanged: (v) => setState(() => _busca = v),
              style: TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: t.buscarNosPedidos,
                hintStyle: TextStyle(color: AppColors.dim2, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: AppColors.dim, size: 19),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, color: AppColors.dim, size: 18),
                        tooltip: t.limparBusca,
                        onPressed: () {
                          _buscaCtrl.clear();
                          setState(() => _busca = '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _cardResumo(econ, total, t.mesNome(_mes), mercadosPorId[filtroMercado]?.nome),
                if (temBusca) ...[
                  const SizedBox(height: 10),
                  _cardBuscaResumo(_busca.trim(), totalBusca, qtdBusca, qtdPedidosBusca),
                ],
                const SizedBox(height: 14),
                if (filtradosBusca.isEmpty)
                  temBusca ? _vazioBusca() : _vazio()
                else
                  ...filtradosBusca.map((pe) => _cardPedido(pe, mercadosPorId, buscaLower)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownAno(List<int> anos) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<int>(
        color: AppColors.surface2,
        onSelected: (a) => setState(() => _ano = a),
        itemBuilder: (_) => [
          for (final a in anos)
            PopupMenuItem(value: a, child: Text('$a')),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$_ano',
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Icon(Icons.arrow_drop_down, color: AppColors.dim, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _barraMeses() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        itemCount: 12,
        itemBuilder: (_, i) {
          final mes = i + 1;
          final sel = mes == _mes;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _mes = mes),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sel ? AppColors.green : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_t.mesAbrev(mes),
                    style: TextStyle(
                      color: sel ? AppColors.onGreen : AppColors.dim,
                      fontSize: 12.5,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    )),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _barraMercados(List<Mercado> mercados, String? filtro) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chipMercado(_t.todos, null, filtro == null,
              () => setState(() => _filtroMercado = null)),
          for (final m in mercados)
            _chipMercado(m.nome, m.cor, filtro == m.id,
                () => setState(() => _filtroMercado = m.id)),
        ],
      ),
    );
  }

  Widget _chipMercado(String label, Color? cor, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.green : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cor != null) ...[
                Container(
                    width: 8,
                    height: 8,
                    decoration:
                        BoxDecoration(color: cor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                    color: sel ? AppColors.onGreen : AppColors.dim,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardResumo(
      double economia, double total, String mesNome, String? mercadoNome) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                    text: _t.emMesEconomizou(mesNome),
                    style: TextStyle(color: AppColors.dim, fontSize: 13)),
                TextSpan(
                    text: reais(economia),
                    style: TextStyle(
                        color: AppColors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ])),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_t.total(reais(total)),
                  style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (mercadoNome != null)
                Text(mercadoNome,
                    style:
                        TextStyle(color: AppColors.dim2, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cardBuscaResumo(String termo, double total, int qtd, int qtdPedidos) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_t.resumoBuscaPedidos(termo, reais(total), qtdPedidos),
                style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
            child: Text('$qtd×', style: TextStyle(color: AppColors.onGreen, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _cardPedido(Pedido pe, Map<String, Mercado> mercadosPorId, [String buscaLower = '']) {
    final mercado = pe.mercadoId == null ? null : mercadosPorId[pe.mercadoId];
    final temBusca = buscaLower.isNotEmpty;
    int qtdMatch = 0;
    double totalMatch = 0;
    if (temBusca) {
      for (final it in pe.itens) {
        if (it.nome.toLowerCase().contains(buscaLower)) {
          qtdMatch += it.quantidade;
          totalMatch += (it.precoUnit ?? 0) * it.quantidade;
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _detalhe(pe, mercado, buscaLower),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                                color: mercado?.cor ?? AppColors.dim2,
                                shape: BoxShape.circle),
                          ),
                          Text(
                            mercado?.nome ?? _t.semMercado,
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        temBusca
                            ? '$qtdMatch× "${_busca.trim()}" · ${reais(totalMatch)}'
                            : '${pe.data == null ? '' : '${diaMes(pe.data!)} · '}${_t.nItens(pe.itens.length)}',
                        style: TextStyle(color: temBusca ? AppColors.green : AppColors.dim, fontSize: 12.5, fontWeight: temBusca ? FontWeight.w600 : FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(temBusca ? reais(totalMatch) : reais(pe.total),
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: temBusca ? AppColors.green : AppColors.text)),
                    if (temBusca)
                      Text(reais(pe.total), style: TextStyle(color: AppColors.dim2, fontSize: 11))
                    else if (pe.economia > 0)
                      Text('−${reais(pe.economia)}',
                          style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppColors.dim2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _detalhe(Pedido pe, Mercado? mercado, [String buscaLower = '']) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
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
              Text(
                '${mercado?.nome ?? _t.semMercado}'
                '${pe.data == null ? '' : ' · ${diaMes(pe.data!)}'}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${_t.total(reais(pe.total))}'
                '${pe.economia > 0 ? '  ·  ${_t.economizou(reais(pe.economia))}' : ''}',
                style: TextStyle(color: AppColors.dim, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.line, height: 1),
              Expanded(
                child: Builder(builder: (context) {
                  final busca = buscaLower;
                  final termo = _busca.trim();
                  final itensExibir = busca.isEmpty
                      ? pe.itens
                      : pe.itens.where((it) => normalizarBusca(it.nome).contains(busca)).toList();
                  return ListView(
                    controller: scroll,
                    children: [
                      if (busca.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
                            child: Text('"$termo" · ${itensExibir.length} ${itensExibir.length == 1 ? 'item' : 'itens'}',
                                style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      for (final it in itensExibir)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(child: _textoComDestaque(it.nome, busca)),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(6)),
                                      child: Text('×${it.quantidade}',
                                          style: TextStyle(color: AppColors.dim, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                    if (it.precoUnit != null) ...[
                                      const SizedBox(width: 6),
                                      Text('${reais(it.precoUnit!)} un',
                                          style: TextStyle(color: AppColors.dim2, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(it.precoUnit == null ? '—' : reais(it.subtotal),
                                  style: TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      if (busca.isNotEmpty && itensExibir.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Center(child: Text(_t.nenhumPedidoComProduto, style: TextStyle(color: AppColors.dim))),
                        ),
                    ],
                  );
                }),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _excluir(pe),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_t.excluirPedido),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _desfazer(pe),
                  icon: const Icon(Icons.undo, size: 18),
                  label: Text(_t.desfazerPedido),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: BorderSide(color: AppColors.blue.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textoComDestaque(String nome, String busca) {
    if (busca.isEmpty) {
      return Text(nome, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text, fontSize: 14));
    }
    final normNome = normalizarBusca(nome);
    final normBusca = normalizarBusca(busca);
    final idx = normNome.indexOf(normBusca);
    if (idx == -1) {
      return Text(nome, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.text, fontSize: 14));
    }
    final antes = nome.substring(0, idx);
    final meio = nome.substring(idx, idx + busca.length);
    final depois = nome.substring(idx + busca.length);
    return Text.rich(
      TextSpan(children: [
        if (antes.isNotEmpty) TextSpan(text: antes, style: TextStyle(color: AppColors.text, fontSize: 14)),
        TextSpan(text: meio, style: TextStyle(color: AppColors.green, fontSize: 14, fontWeight: FontWeight.w700)),
        if (depois.isNotEmpty) TextSpan(text: depois, style: TextStyle(color: AppColors.text, fontSize: 14)),
      ]),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _vazioBusca() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: AppColors.dim2),
          const SizedBox(height: 12),
          Text(_t.nenhumPedidoComProduto, textAlign: TextAlign.center, style: TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _vazio() {
    return Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.dim2),
          const SizedBox(height: 14),
          Text(_t.nenhumaCompraEm(_t.mesNome(_mes), _ano),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(_t.finalizeUmaCompra,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }
}
