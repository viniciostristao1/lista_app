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

  // read (não watch): usado tanto no build quanto em callbacks; a reatividade
  // vem do ref.watch(stringsProvider) no topo do build.
  AppStrings get _t => ref.read(stringsProvider);

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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _cardResumo(econ, total, t.mesNome(_mes),
                    mercadosPorId[filtroMercado]?.nome),
                const SizedBox(height: 14),
                if (filtrados.isEmpty)
                  _vazio()
                else
                  ...filtrados.map((pe) => _cardPedido(pe, mercadosPorId)),
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

  Widget _cardPedido(Pedido pe, Map<String, Mercado> mercadosPorId) {
    final mercado = pe.mercadoId == null ? null : mercadosPorId[pe.mercadoId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _detalhe(pe, mercado),
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
                        '${pe.data == null ? '' : '${diaMes(pe.data!)} · '}'
                        '${_t.nItens(pe.itens.length)}',
                        style: TextStyle(color: AppColors.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(reais(pe.total),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    if (pe.economia > 0)
                      Text('−${reais(pe.economia)}',
                          style: TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
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

  void _detalhe(Pedido pe, Mercado? mercado) {
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
                child: ListView(
                  controller: scroll,
                  children: [
                    for (final it in pe.itens)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(it.nome,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppColors.text, fontSize: 14)),
                                  ),
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
                  ],
                ),
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
