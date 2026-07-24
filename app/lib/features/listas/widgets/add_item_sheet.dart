import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Abre o painel para adicionar um item à lista [listaId].
Future<void> mostrarAdicionarItem(BuildContext context, String listaId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AddItemSheet(listaId: listaId),
  );
}

class _AddItemSheet extends ConsumerStatefulWidget {
  const _AddItemSheet({required this.listaId});
  final String listaId;

  @override
  ConsumerState<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<_AddItemSheet> {
  final _nomeCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  Categoria _categoria = Categoria.mercearia;
  String? _mercadoId;
  int _qtd = 1;
  bool _salvando = false;
  String _query = '';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  void _escolherSugestao(Produto p) {
    setState(() {
      _nomeCtrl.text = p.nome;
      _query = p.nome;
      _categoria = p.categoria;
      if (p.ultimoPreco != null) {
        _precoCtrl.text = p.ultimoPreco!.toStringAsFixed(2).replaceAll('.', ',');
      }
      if (p.ultimoMercadoId != null) _mercadoId = p.ultimoMercadoId;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _adicionar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dá um nome pro item 🙂')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final preco = parsePreco(_precoCtrl.text);
      final produtoId = await ref.read(produtosRepoProvider).registrar(
            nome: nome,
            categoria: _categoria,
            preco: preco,
            mercadoId: _mercadoId,
          );
      await ref.read(listasRepoProvider).adicionarItem(
            widget.listaId,
            produtoId: produtoId,
            nome: nome,
            categoria: _categoria,
            quantidade: _qtd,
            preco: preco,
            mercadoId: _mercadoId,
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final mercados = ref.watch(mercadosProvider).asData?.value ?? [];

    // sugestões do catálogo que batem com o que foi digitado
    final q = _query.trim().toLowerCase();
    final todos = ref.watch(produtosProvider).asData?.value ?? [];
    final sugestoes = q.isEmpty
        ? const <Produto>[]
        : todos
            .where((p) => p.nomeLower.contains(q) && p.nomeLower != q)
            .take(4)
            .toList();
    final jaExiste = todos.any((p) => p.nomeLower == q);

    return Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 10, bottom: bottom + 24),
      child: SingleChildScrollView(
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
            const Text('Adicionar item',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Nome já basta — preço e mercado são opcionais.',
                style: TextStyle(color: AppColors.dim, fontSize: 12.5)),
            const SizedBox(height: 14),

            // nome
            TextField(
              controller: _nomeCtrl,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _dec(hint: 'Digite o nome (ex: café)', icon: Icons.search),
            ),

            // sugestões
            if (sugestoes.isNotEmpty || (q.isNotEmpty && !jaExiste)) ...[
              const SizedBox(height: 10),
              for (final p in sugestoes)
                _linhaSugestao(
                  icone: Icons.history,
                  titulo: p.nome,
                  sub: p.categoria.label,
                  onTap: () => _escolherSugestao(p),
                ),
              if (q.isNotEmpty && !jaExiste)
                _linhaSugestao(
                  icone: Icons.add,
                  titulo: 'Cadastrar "${_nomeCtrl.text.trim()}" como novo',
                  cor: AppColors.green,
                  onTap: () => FocusScope.of(context).unfocus(),
                ),
            ],

            const SizedBox(height: 16),
            _label('Categoria'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in Categoria.values)
                  _chip(
                    selecionado: _categoria == c,
                    onTap: () => setState(() => _categoria = c),
                    child: Text(c.label),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            _label('Preço (opcional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _precoCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _dec(hint: '0,00', prefix: 'R\$  '),
            ),

            if (mercados.isNotEmpty) ...[
              const SizedBox(height: 16),
              _label('Mercado (opcional)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in mercados)
                    _chip(
                      selecionado: _mercadoId == m.id,
                      onTap: () => setState(() =>
                          _mercadoId = _mercadoId == m.id ? null : m.id),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(right: 7),
                            decoration:
                                BoxDecoration(color: m.cor, shape: BoxShape.circle),
                          ),
                          Text(m.nome),
                        ],
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            _label('Quantidade'),
            const SizedBox(height: 8),
            Row(
              children: [
                _stepBtn(Icons.remove, () {
                  if (_qtd > 1) setState(() => _qtd--);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('$_qtd',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                _stepBtn(Icons.add, () => setState(() => _qtd++)),
              ],
            ),

            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _salvando ? null : _adicionar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.onGreen,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_salvando ? 'Adicionando…' : 'Adicionar à lista'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- helpers de UI ----

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.dim, fontSize: 12, fontWeight: FontWeight.w600));

  InputDecoration _dec({String? hint, IconData? icon, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.dim2),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.dim, size: 20) : null,
      prefixText: prefix,
      prefixStyle: const TextStyle(color: AppColors.dim, fontSize: 15),
      isDense: true,
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.green),
      ),
    );
  }

  Widget _linhaSugestao({
    required IconData icone,
    required String titulo,
    String? sub,
    Color? cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Icon(icone, size: 18, color: cor ?? AppColors.dim),
            const SizedBox(width: 11),
            Expanded(
              child: Text(titulo,
                  style: TextStyle(
                      color: cor ?? AppColors.text,
                      fontWeight: cor != null ? FontWeight.w600 : FontWeight.w400)),
            ),
            if (sub != null)
              Text(sub, style: const TextStyle(color: AppColors.dim2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required bool selecionado,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.green.withValues(alpha: 0.14) : AppColors.bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selecionado ? AppColors.green : AppColors.lineStrong,
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 13,
            color: selecionado ? AppColors.green : AppColors.dim,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.lineStrong),
        ),
        child: Icon(icon, size: 20, color: AppColors.text),
      ),
    );
  }
}
