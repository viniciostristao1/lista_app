import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/pedido.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/pedidos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Histórico de compras finalizadas + resumo do mês. Filtro por mercado no topo.
class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  String? _filtroMercado; // null = "Todos"

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
      Navigator.pop(context); // fecha a folha de detalhe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido desfeito — itens voltaram pra lista 🔄')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = ref.watch(pedidosProvider).asData?.value ?? const [];
    final mercados = ref.watch(mercadosProvider).asData?.value ?? const [];
    final mercadosPorId = {for (final m in mercados) m.id: m};

    final filtro =
        (_filtroMercado != null && mercados.any((m) => m.id == _filtroMercado))
            ? _filtroMercado
            : null;

    final filtrados =
        pedidos.where((pe) => filtro == null || pe.mercadoId == filtro).toList();

    // resumo do mês atual
    final now = DateTime.now();
    var mesEcon = 0.0, mesTotal = 0.0;
    for (final pe in filtrados) {
      final d = pe.data;
      if (d != null && d.year == now.year && d.month == now.month) {
        mesEcon += pe.economia;
        mesTotal += pe.total;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      body: Column(
        children: [
          if (mercados.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: _barraFiltro(mercados, filtro),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
              children: [
                _cardMes(mesEcon, mesTotal, mercadosPorId[filtro]?.nome),
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

  Widget _barraFiltro(List<Mercado> mercados, String? filtro) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _chip('Todos', null, filtro == null,
              () => setState(() => _filtroMercado = null)),
          for (final m in mercados)
            _chip(m.nome, m.cor, filtro == m.id,
                () => setState(() => _filtroMercado = m.id)),
        ],
      ),
    );
  }

  Widget _chip(String label, Color? cor, bool sel, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sel ? AppColors.green.withValues(alpha: 0.14) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? AppColors.green : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cor != null) ...[
                Container(
                    width: 9,
                    height: 9,
                    decoration:
                        BoxDecoration(color: cor, shape: BoxShape.circle)),
                const SizedBox(width: 7),
              ],
              Text(label,
                  style: TextStyle(
                    color: sel ? AppColors.green : AppColors.dim,
                    fontSize: 12.5,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardMes(double economia, double total, String? mercadoNome) {
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Este mês economizou ',
                    style: TextStyle(color: AppColors.dim, fontSize: 13)),
                TextSpan(
                    text: reais(economia),
                    style: const TextStyle(
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
              Text('Total ${reais(total)}',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              if (mercadoNome != null)
                Text(mercadoNome,
                    style:
                        const TextStyle(color: AppColors.dim2, fontSize: 11.5)),
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
                            mercado?.nome ?? 'Vários mercados',
                            style: const TextStyle(
                                fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pe.data == null ? '' : '${diaMes(pe.data!)} · '}'
                        '${pe.itens.length} ${pe.itens.length == 1 ? 'item' : 'itens'}',
                        style: const TextStyle(color: AppColors.dim, fontSize: 12.5),
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
                          style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.dim2),
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
                '${mercado?.nome ?? 'Vários mercados'}'
                '${pe.data == null ? '' : ' · ${diaMes(pe.data!)}'}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                'Total ${reais(pe.total)}'
                '${pe.economia > 0 ? '  ·  economizou ${reais(pe.economia)}' : ''}',
                style: const TextStyle(color: AppColors.dim, fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.line, height: 1),
              Expanded(
                child: ListView(
                  controller: scroll,
                  children: [
                    for (final it in pe.itens)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                it.quantidade > 1
                                    ? '${it.nome}  ×${it.quantidade}'
                                    : it.nome,
                                style: const TextStyle(
                                    color: AppColors.text, fontSize: 14),
                              ),
                            ),
                            Text(
                              it.precoUnit == null ? '—' : reais(it.subtotal),
                              style: const TextStyle(
                                  color: AppColors.dim, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _desfazer(pe),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Desfazer pedido (voltar itens à lista)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: BorderSide(color: AppColors.blue.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    return const Padding(
      padding: EdgeInsets.only(top: 50),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.dim2),
          SizedBox(height: 14),
          Text('Nenhuma compra por aqui',
              style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Finalize uma compra na aba Listas\npara ela aparecer aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.dim, fontSize: 13)),
        ],
      ),
    );
  }
}
