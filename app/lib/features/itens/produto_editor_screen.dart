import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Abre a tela de cadastrar/editar um produto (campos + preços por mercado).
Future<void> mostrarEditorProduto(
  BuildContext context,
  Produto? produto,
  List<Mercado> mercados,
) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ProdutoEditorScreen(produto: produto, mercados: mercados),
    ),
  );
}

class ProdutoEditorScreen extends ConsumerStatefulWidget {
  const ProdutoEditorScreen({super.key, this.produto, required this.mercados});

  final Produto? produto;
  final List<Mercado> mercados;

  @override
  ConsumerState<ProdutoEditorScreen> createState() =>
      _ProdutoEditorScreenState();
}

class _ProdutoEditorScreenState extends ConsumerState<ProdutoEditorScreen> {
  late final TextEditingController _nome;
  late final TextEditingController _marca;
  late final TextEditingController _tamanho;
  late final TextEditingController _unidade;
  late final TextEditingController _obs;
  late Categoria _categoria;
  late bool _fixado;
  late final Map<String, TextEditingController> _precoCtrls;
  bool _salvando = false;

  Produto? get _p => widget.produto;
  bool get _editando => _p != null;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: _p?.nome ?? '');
    _marca = TextEditingController(text: _p?.marca ?? '');
    _tamanho = TextEditingController(text: _p?.tamanho ?? '');
    _unidade = TextEditingController(text: _p?.unidade ?? '');
    _obs = TextEditingController(text: _p?.observacoes ?? '');
    _categoria = _p?.categoria ?? Categoria.mercearia;
    _fixado = _p?.fixado ?? false;
    _precoCtrls = {
      for (final m in widget.mercados)
        m.id: TextEditingController(
          text: _p?.precos[m.id] != null
              ? valorEditavel(_p!.precos[m.id]!.valor)
              : '',
        ),
    };
  }

  @override
  void dispose() {
    _nome.dispose();
    _marca.dispose();
    _tamanho.dispose();
    _unidade.dispose();
    _obs.dispose();
    for (final c in _precoCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nuloSeVazio(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dá um nome pro produto 🙂')),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final repo = ref.read(produtosRepoProvider);
      final String id;
      if (_editando) {
        id = _p!.id;
        await repo.atualizarProduto(
          id,
          nome: nome,
          categoria: _categoria,
          marca: _nuloSeVazio(_marca),
          tamanho: _nuloSeVazio(_tamanho),
          unidade: _nuloSeVazio(_unidade),
          observacoes: _nuloSeVazio(_obs),
          fixado: _fixado,
        );
      } else {
        id = await repo.criarProduto(
          nome: nome,
          categoria: _categoria,
          marca: _nuloSeVazio(_marca),
          tamanho: _nuloSeVazio(_tamanho),
          unidade: _nuloSeVazio(_unidade),
          observacoes: _nuloSeVazio(_obs),
          fixado: _fixado,
        );
        if (_fixado) {
          final listaRepo = ref.read(listasRepoProvider);
          final atual = await listaRepo.obterOuCriarAtiva();
          await listaRepo.adicionarProdutoSeAusente(atual.id,
              produtoId: id, nome: nome, categoria: _categoria);
        }
      }

      for (final m in widget.mercados) {
        final novo = parsePreco(_precoCtrls[m.id]!.text);
        final antigo = _p?.precos[m.id]?.valor;
        if (novo == null && antigo != null) {
          await repo.removerPreco(id, m.id);
        } else if (novo != null &&
            (antigo == null || (novo - antigo).abs() > 0.001)) {
          await repo.definirPreco(id, m.id, novo);
        }
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _excluir() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir produto?'),
        content: const Text('Remove o produto do catálogo e seus preços.'),
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
      await ref.read(produtosRepoProvider).excluirProduto(_p!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar item' : 'Novo item'),
        actions: [
          IconButton(
            tooltip: _fixado ? 'Fixado (não sai ao finalizar)' : 'Fixar item',
            icon: Icon(_fixado ? Icons.push_pin : Icons.push_pin_outlined,
                color: _fixado ? AppColors.green : AppColors.dim),
            onPressed: () async {
              final novo = !_fixado;
              setState(() => _fixado = novo);
              if (!_editando) return;
              await ref.read(produtosRepoProvider).setFixado(_p!.id, novo);
              // fixar -> vai pra lista; desfixar -> sai da lista
              final listaRepo = ref.read(listasRepoProvider);
              final atual = await listaRepo.obterOuCriarAtiva();
              if (novo) {
                await listaRepo.adicionarProdutoSeAusente(atual.id,
                    produtoId: _p!.id, nome: _p!.nome, categoria: _p!.categoria);
              } else {
                await listaRepo.removerItensPorProduto(atual.id, _p!.id);
              }
            },
          ),
          if (_editando)
            IconButton(
              tooltip: 'Excluir',
              icon: const Icon(Icons.delete_outline, color: AppColors.dim),
              onPressed: _excluir,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          if (_fixado)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Row(children: [
                Icon(Icons.push_pin, size: 15, color: AppColors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Item fixado — não sai ao "Finalizar compra".',
                      style: TextStyle(color: AppColors.green, fontSize: 12.5)),
                ),
              ]),
            ),
          _label('Nome'),
          const SizedBox(height: 8),
          TextField(
            controller: _nome,
            autofocus: !_editando,
            style: const TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec('Ex: Café Pilão'),
          ),
          const SizedBox(height: 18),
          _label('Marca (opcional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _marca,
            style: const TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec('Ex: Pilão'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Peso (opcional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tamanho,
                      style:
                          const TextStyle(color: AppColors.text, fontSize: 15),
                      decoration: _dec('Ex: 500'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unidade (opcional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unidade,
                      style:
                          const TextStyle(color: AppColors.text, fontSize: 15),
                      decoration: _dec('Ex: g, kg, L, un'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _label('Preço por mercado'),
          const SizedBox(height: 4),
          if (widget.mercados.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Cadastre seus mercados primeiro (aba Itens → Editar mercados).',
                style: TextStyle(color: AppColors.dim2, fontSize: 12.5),
              ),
            )
          else
            ...widget.mercados.map(_linhaPreco),
          const SizedBox(height: 22),
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
                  texto: c.label,
                ),
            ],
          ),
          const SizedBox(height: 22),
          _label('Observações (opcional)'),
          const SizedBox(height: 8),
          TextField(
            controller: _obs,
            minLines: 2,
            maxLines: 4,
            style: const TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec('Ex: marca preferida, ponto da fruta, promoção…'),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _salvando ? null : _salvar,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.onGreen,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_salvando ? 'Salvando…' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaPreco(Mercado m) {
    final atual = _p?.precos[m.id];
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(color: m.cor, shape: BoxShape.circle),
          ),
          SizedBox(
            width: 92,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.text, fontSize: 14)),
                if (atual != null)
                  Text(
                    atual.desatualizado
                        ? 'desatualizado (${haDias(atual.diasDesde)})'
                        : haDias(atual.diasDesde),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          atual.desatualizado ? AppColors.danger : AppColors.dim2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _precoCtrls[m.id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _dec('R\$ —', prefix: 'R\$  '),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(
          color: AppColors.dim, fontSize: 12, fontWeight: FontWeight.w600));

  InputDecoration _dec(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.dim2),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: AppColors.dim, fontSize: 15),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
    );
  }

  Widget _chip({
    required bool selecionado,
    required VoidCallback onTap,
    required String texto,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selecionado
              ? AppColors.green.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
          border:
              Border.all(color: selecionado ? AppColors.green : AppColors.line),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 13,
                color: selecionado ? AppColors.green : AppColors.dim)),
      ),
    );
  }
}
