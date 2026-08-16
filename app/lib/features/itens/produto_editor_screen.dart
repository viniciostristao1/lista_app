import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/l10n/strings.dart';
import 'package:lista_app/models/categoria.dart';
import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/models/produto.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';
import 'package:lista_app/util/format.dart';

/// Abre a tela de cadastrar/editar um produto (campos + preços por mercado).
Future<void> mostrarEditorProduto(
  BuildContext context,
  Produto? produto,
  List<Mercado> mercados, {
  String? nomeInicial,
}) {
  return Navigator.push<void>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ProdutoEditorScreen(
          produto: produto, mercados: mercados, nomeInicial: nomeInicial),
    ),
  );
}

class ProdutoEditorScreen extends ConsumerStatefulWidget {
  const ProdutoEditorScreen(
      {super.key, this.produto, required this.mercados, this.nomeInicial});

  final Produto? produto;
  final List<Mercado> mercados;

  /// Nome pré-preenchido ao cadastrar um item NOVO (produto == null).
  final String? nomeInicial;

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
  late bool _recorrente; // = "fixado": não sai ao finalizar (exige mercado fixo)
  String? _mercadoFixo; // item "de um mercado só" (null = comparável)
  bool _abrirMercadoFixo = false; // abriu o modo "num mercado só"
  late final Map<String, TextEditingController> _precoCtrls;
  bool _salvando = false;

  Produto? get _p => widget.produto;
  bool get _editando => _p != null;

  // read (não watch): serve build e callbacks; a reatividade vem do
  // ref.watch(stringsProvider) no topo do build.
  AppStrings get _t => ref.read(stringsProvider);

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: _p?.nome ?? widget.nomeInicial ?? '');
    _marca = TextEditingController(text: _p?.marca ?? '');
    _tamanho = TextEditingController(text: _p?.tamanho ?? '');
    _unidade = TextEditingController(text: _p?.unidade ?? '');
    _obs = TextEditingController(text: _p?.observacoes ?? '');
    _categoria = _p?.categoria ?? Categoria.mercearia;
    _recorrente = _p?.fixado ?? false;
    _mercadoFixo = _p?.mercadoFixo;
    _abrirMercadoFixo = _mercadoFixo != null;
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
        SnackBar(content: Text(_t.deUmNomeProduto)),
      );
      return;
    }
    final dedicado = _mercadoFixo != null;
    // Abriu "num mercado só" mas não escolheu um mercado → alerta e não salva.
    if (_abrirMercadoFixo && !dedicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.escolhaMercadoOuVoltar)),
      );
      return;
    }
    if (_recorrente && !dedicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t.escolhaMercadoRecorrente)),
      );
      return;
    }
    setState(() => _salvando = true);
    try {
      final repo = ref.read(produtosRepoProvider);
      final eraRecorrente = _p?.fixado ?? false;
      // Data das observações: carimba "agora" ao criar com obs ou ao mudar o
      // texto; mantém a data antiga se o texto não mudou; zera ao apagar.
      final obs = _nuloSeVazio(_obs);
      final obsData = obs == null
          ? null
          : (obs != _p?.observacoes ? DateTime.now() : _p?.observacoesAtualizadasEm);
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
          observacoes: obs,
          observacoesAtualizadasEm: obsData,
          fixado: _recorrente,
          mercadoFixo: _mercadoFixo,
        );
      } else {
        id = await repo.criarProduto(
          nome: nome,
          categoria: _categoria,
          marca: _nuloSeVazio(_marca),
          tamanho: _nuloSeVazio(_tamanho),
          unidade: _nuloSeVazio(_unidade),
          observacoes: obs,
          observacoesAtualizadasEm: obsData,
          fixado: _recorrente,
          mercadoFixo: _mercadoFixo,
        );
      }

      // Preços só no modo comparar. Item dedicado não tem preço (mantém os
      // preços antigos no banco intactos, para "voltar a comparar" restaurá-los).
      if (!dedicado) {
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
      }

      // Recorrente entra na lista; deixar de ser recorrente sai da lista.
      if (_recorrente != eraRecorrente) {
        final listaRepo = ref.read(listasRepoProvider);
        final atual = await listaRepo.obterOuCriarAtiva();
        if (_recorrente) {
          await listaRepo.adicionarProdutoSeAusente(atual.id,
              produtoId: id, nome: nome, categoria: _categoria);
        } else {
          await listaRepo.removerItensPorProduto(atual.id, id);
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
        title: Text(_t.excluirProdutoTitulo),
        content: Text(_t.excluirProdutoMsg),
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
    if (ok == true) {
      await ref.read(produtosRepoProvider).excluirProduto(_p!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? t.editarItem : t.novoItem),
        actions: [
          if (_editando)
            IconButton(
              tooltip: t.excluir,
              icon: Icon(Icons.delete_outline, color: AppColors.dim),
              onPressed: _excluir,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
        children: [
          if (_recorrente)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(children: [
                Icon(Icons.push_pin, size: 15, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.compraRecorrenteNaoSai,
                      style: TextStyle(color: AppColors.green, fontSize: 12.5)),
                ),
              ]),
            ),
          _label(t.nome),
          const SizedBox(height: 8),
          TextField(
            controller: _nome,
            autofocus: !_editando,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec(t.exNomeProduto),
          ),
          const SizedBox(height: 18),
          _label(t.marcaOpcional),
          const SizedBox(height: 8),
          TextField(
            controller: _marca,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec(t.exMarca),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(t.pesoOpcional),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _tamanho,
                      style:
                          TextStyle(color: AppColors.text, fontSize: 15),
                      decoration: _dec(t.exPeso),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(t.unidadeOpcional),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _unidade,
                      style:
                          TextStyle(color: AppColors.text, fontSize: 15),
                      decoration: _dec(t.exUnidade),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _secaoMercado(),
          const SizedBox(height: 22),
          _label(t.categoria),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in Categoria.values)
                _chip(
                  selecionado: _categoria == c,
                  onTap: () => setState(() => _categoria = c),
                  texto: t.categoria_(c),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _label(t.observacoesOpcional),
              const Spacer(),
              // Data da última observação gravada — mostra só quando há uma
              // observação salva (produtos antigos caem no updatedAt).
              if (_p?.observacoes != null && _p!.observacoesData != null)
                Text(
                  '${t.atualizadasEm} '
                  '${dataCompleta(_p!.observacoesData!)}',
                  style: TextStyle(
                      color: AppColors.dim2,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _obs,
            minLines: 2,
            maxLines: 4,
            style: TextStyle(color: AppColors.text, fontSize: 15),
            decoration: _dec(t.exObservacoes),
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
              child: Text(_salvando ? t.salvando : t.salvar),
            ),
          ),
        ],
      ),
    );
  }

  /// Seção "preço/mercado": modo comparar (grade de preço + botão) OU modo
  /// "num mercado só" (escolhe mercado + recorrente, sem preço).
  Widget _secaoMercado() {
    final t = _t;
    if (widget.mercados.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(t.precoPorMercado),
          const SizedBox(height: 6),
          Text(
            t.cadastreMercadosPrimeiro,
            style: TextStyle(color: AppColors.dim2, fontSize: 12.5),
          ),
        ],
      );
    }

    final dedicando = _abrirMercadoFixo || _mercadoFixo != null;
    if (!dedicando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(t.precoPorMercado),
          ...widget.mercados.map(_linhaPreco),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => setState(() => _abrirMercadoFixo = true),
              icon: Icon(Icons.storefront_outlined,
                  size: 18, color: AppColors.green),
              label: Text(t.comprarSempreNumMercado,
                  style: TextStyle(color: AppColors.green, fontSize: 13.5)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(t.comprarSempreNumMercado),
        const SizedBox(height: 4),
        Text(t.semComparacaoAnote,
            style: TextStyle(color: AppColors.dim2, fontSize: 12.5)),
        const SizedBox(height: 12),
        // Caixa de alerta: fica realçada enquanto nenhum mercado é escolhido.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: _mercadoFixo == null
                ? AppColors.danger.withValues(alpha: 0.08)
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _mercadoFixo == null
                    ? AppColors.danger
                    : AppColors.lineStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _mercadoFixo == null
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 15,
                    color: _mercadoFixo == null
                        ? AppColors.danger
                        : AppColors.green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _mercadoFixo == null
                        ? t.selecionarMercadoObrig
                        : t.mercadoSelecionado,
                    style: TextStyle(
                        color: _mercadoFixo == null
                            ? AppColors.danger
                            : AppColors.dim,
                        fontSize: 12.5),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final m in widget.mercados) _chipMercado(m)],
              ),
            ],
          ),
        ),
        CheckboxListTile(
          value: _recorrente,
          onChanged: _mercadoFixo == null
              ? null
              : (v) => setState(() => _recorrente = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          activeColor: AppColors.green,
          title: Text(t.compraRecorrenteCheck,
              style: TextStyle(color: AppColors.text, fontSize: 13.5)),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => setState(() {
              _abrirMercadoFixo = false;
              _mercadoFixo = null;
              _recorrente = false;
            }),
            icon: Icon(Icons.arrow_back, size: 18, color: AppColors.green),
            label: Text(t.voltarComparar,
                style: TextStyle(color: AppColors.green, fontSize: 13.5)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.surface2,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chipMercado(Mercado m) {
    final sel = _mercadoFixo == m.id;
    return GestureDetector(
      onTap: () => setState(() => _mercadoFixo = m.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: m.cor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(m.nome,
                style: TextStyle(
                    color: sel ? AppColors.onGreen : AppColors.dim,
                    fontSize: 13,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _linhaPreco(Mercado m) {
    final t = _t;
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
                        TextStyle(color: AppColors.text, fontSize: 14)),
                if (atual != null)
                  Text(
                    atual.desatualizado
                        ? t.desatualizadoHa(t.haDias(atual.diasDesde))
                        : t.haDias(atual.diasDesde),
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
              style: TextStyle(color: AppColors.text, fontSize: 15),
              decoration: _dec('R\$ —', prefix: 'R\$  '),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(
          color: AppColors.dim, fontSize: 12, fontWeight: FontWeight.w600));

  InputDecoration _dec(String hint, {String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.dim2),
      prefixText: prefix,
      prefixStyle: TextStyle(color: AppColors.dim, fontSize: 15),
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          color: selecionado ? AppColors.green : AppColors.surface,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 13,
                color: selecionado ? AppColors.onGreen : AppColors.dim)),
      ),
    );
  }
}
