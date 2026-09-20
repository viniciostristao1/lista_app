import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/models/mercado.dart';
import 'package:lista_app/services/mercados_repository.dart';
import 'package:lista_app/services/prefs.dart';
import 'package:lista_app/services/produtos_repository.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Abre o editor "Meus mercados" (até 8, com nome e cor) e a ordem manual da
/// prateleira (arrastar, com o "Automático" desligado).
Future<void> mostrarEditorMercados(BuildContext context, List<Mercado> atuais) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EditorMercados(atuais: atuais),
  );
}

class _Slot {
  _Slot(
      {this.id,
      required this.localId,
      required String nome,
      required this.cor,
      this.preferencia = false,
      this.novo = false})
      : nomeCtrl = TextEditingController(text: nome);
  String? id;
  final int localId; // chave estável p/ o arrastar antes de ter id no banco
  final TextEditingController nomeCtrl;
  Color cor;
  bool preferencia;
  bool novo; // recém-adicionado → autofoca o campo
}

class _EditorMercados extends ConsumerStatefulWidget {
  const _EditorMercados({required this.atuais});
  final List<Mercado> atuais;

  @override
  ConsumerState<_EditorMercados> createState() => _EditorMercadosState();
}

class _EditorMercadosState extends ConsumerState<_EditorMercados> {
  static const _maxMercados = 8;
  late List<_Slot> _slots;

  /// Ordem da prateleira no modo manual: ids de mercado + tokens fixos
  /// "Todos" e "Sem mercado" (ver mercados_repository.dart).
  late List<String> _ordemMista;
  int _proximoLocal = 0;
  late Set<String> _idsIniciais;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _slots = widget.atuais
        .map((m) => _Slot(
            id: m.id,
            localId: _proximoLocal++,
            nome: m.nome,
            cor: m.cor,
            preferencia: m.preferencia))
        .toList();
    _idsIniciais = widget.atuais.map((m) => m.id).toSet();
    _ordemMista = _montarOrdemInicial();
  }

  String _tokenDe(_Slot s) => s.id ?? 'novo:${s.localId}';

  /// Ordem de partida do modo manual: a ordem salva (com ids que ainda existem)
  /// ou, na 1ª vez, o espelho da ordem automática: favoritos → Todos → demais
  /// → Sem mercado. Mercados novos entram antes do "Sem mercado".
  List<String> _montarOrdemInicial() {
    final salva = ref.read(mercadosOrdemProvider);
    final ordem = <String>[];
    if (salva.isEmpty) {
      for (final s in _slots) {
        if (s.preferencia) ordem.add(_tokenDe(s));
      }
      ordem.add(tokenTodos);
      for (final s in _slots) {
        if (!s.preferencia) ordem.add(_tokenDe(s));
      }
      ordem.add(tokenSemMercado);
      return ordem;
    }
    for (final token in salva) {
      if (token == tokenTodos || token == tokenSemMercado) {
        if (!ordem.contains(token)) ordem.add(token);
      } else if (_slots.any((s) => s.id == token)) {
        if (!ordem.contains(token)) ordem.add(token);
      }
    }
    if (!ordem.contains(tokenTodos)) ordem.insert(0, tokenTodos);
    final faltantes = [
      for (final s in _slots)
        if (!ordem.contains(_tokenDe(s))) _tokenDe(s),
    ];
    if (faltantes.isNotEmpty) {
      final i = ordem.indexOf(tokenSemMercado);
      ordem.insertAll(i == -1 ? ordem.length : i, faltantes);
    }
    if (!ordem.contains(tokenSemMercado)) ordem.add(tokenSemMercado);
    return ordem;
  }

  /// Salva a ordem atual (só o que existe de fato: tokens + ids válidos).
  Future<void> _persistirOrdem() async {
    final validos = _slots.map((s) => s.id).whereType<String>().toSet();
    final ordem = [
      for (final token in _ordemMista)
        if (token == tokenTodos ||
            token == tokenSemMercado ||
            validos.contains(token))
          token,
    ];
    await ref.read(mercadosOrdemProvider.notifier).definir(ordem);
  }

  Future<void> _alternarAuto(bool ligado) async {
    await ref.read(mercadosAutoProvider.notifier).definir(ligado);
    // Ao desligar, já grava a ordem que está na tela (sem susto visual).
    if (!ligado) await _persistirOrdem();
  }

  // Só um mercado pode ser preferência: marca este e desmarca os outros.
  void _togglePreferencia(int i) {
    setState(() {
      final novo = !_slots[i].preferencia;
      for (final s in _slots) {
        s.preferencia = false;
      }
      _slots[i].preferencia = novo;
    });
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.nomeCtrl.dispose();
    }
    super.dispose();
  }

  void _adicionar() {
    if (_slots.length >= _maxMercados) return;
    setState(() {
      final cor =
          AppColors.mercadoCores[_slots.length % AppColors.mercadoCores.length];
      final slot = _Slot(nome: '', cor: cor, novo: true, localId: _proximoLocal++);
      _slots.add(slot);
      final i = _ordemMista.indexOf(tokenSemMercado);
      _ordemMista.insert(i == -1 ? _ordemMista.length : i, _tokenDe(slot));
    });
  }

  void _remover(int i) {
    setState(() {
      final slot = _slots.removeAt(i);
      _ordemMista.remove(_tokenDe(slot));
      slot.nomeCtrl.dispose();
    });
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    final repo = ref.read(mercadosRepoProvider);
    try {
      final restantes =
          _slots.where((s) => s.id != null).map((s) => s.id!).toSet();
      for (final id in _idsIniciais) {
        if (!restantes.contains(id)) {
          await repo.excluir(id);
          // some com os preços desse mercado em todos os produtos
          await ref.read(produtosRepoProvider).removerMercadoDeTodos(id);
        }
      }
      for (final s in _slots) {
        final nome = s.nomeCtrl.text.trim();
        if (nome.isEmpty) continue;
        if (s.id == null) {
          final id = await repo.criar(
              nome: nome, cor: s.cor, preferencia: s.preferencia);
          // troca o token temporário pelo id real, mantendo a posição.
          final temp = 'novo:${s.localId}';
          final i = _ordemMista.indexOf(temp);
          if (i != -1) _ordemMista[i] = id;
          s.id = id;
        } else {
          await repo.atualizar(s.id!,
              nome: nome, cor: s.cor, preferencia: s.preferencia);
        }
      }
      await _persistirOrdem();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final auto = ref.watch(mercadosAutoProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      // empurra a folha pra cima do teclado
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        // limita a altura; a lista rola, o botão Salvar fica fixo embaixo
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
            Row(
              children: [
                Expanded(
                  child: Text(t.meusMercados,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600)),
                ),
                Text(t.automatico,
                    style: TextStyle(color: AppColors.dim, fontSize: 13)),
                const SizedBox(width: 6),
                Switch(
                  value: auto,
                  onChanged: _alternarAuto,
                  activeThumbColor: AppColors.onGreen,
                  activeTrackColor: AppColors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            if (!auto)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 2),
                child: Text(t.dicaArrastarMercados,
                    style: TextStyle(color: AppColors.dim2, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            Flexible(
              child: auto
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < _slots.length; i++) _linha(i),
                          if (_slots.length < _maxMercados) _botaoAdicionar(),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: _ordemMista.length,
                      onReorderItem: (oldI, newI) {
                        setState(() {
                          _ordemMista.insert(newI, _ordemMista.removeAt(oldI));
                        });
                        _persistirOrdem();
                      },
                      itemBuilder: (ctx, i) => _linhaDaOrdem(i),
                      footer:
                          _slots.length < _maxMercados ? _botaoAdicionar() : null,
                    ),
            ),
            const SizedBox(height: 8),
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
                child: Text(_salvando ? t.salvando : t.salvarMercados),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoAdicionar() {
    final t = ref.watch(stringsProvider);
    return TextButton.icon(
      onPressed: _adicionar,
      icon: Icon(Icons.add, size: 18, color: AppColors.green),
      label: Text(t.adicionarMercado, style: TextStyle(color: AppColors.green)),
    );
  }

  /// Linha da ordem manual: "Todos" / "Sem mercado" fixos ou um mercado.
  Widget _linhaDaOrdem(int i) {
    final token = _ordemMista[i];
    if (token == tokenTodos || token == tokenSemMercado) {
      return _linhaFixa(token, i);
    }
    final slotIndex = _slots.indexWhere((s) => _tokenDe(s) == token);
    if (slotIndex == -1) return SizedBox.shrink(key: ValueKey(token));
    return _linha(slotIndex, dragIndex: i);
  }

  /// Linha fixa (não é mercado): só rótulo + o pino de arrastar.
  Widget _linhaFixa(String token, int index) {
    final t = ref.watch(stringsProvider);
    final ehTodos = token == tokenTodos;
    return Container(
      key: ValueKey(token),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lineStrong),
            ),
            child: Icon(
                ehTodos ? Icons.select_all : Icons.location_off_outlined,
                size: 16,
                color: AppColors.dim),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ehTodos ? t.todos : t.semMercado,
                style: TextStyle(color: AppColors.text, fontSize: 15)),
          ),
          _pinoArrastar(index),
        ],
      ),
    );
  }

  Widget _pinoArrastar(int index) {
    return ReorderableDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(Icons.drag_indicator, color: AppColors.dim2, size: 22),
      ),
    );
  }

  Widget _linha(int i, {int? dragIndex}) {
    final t = ref.watch(stringsProvider);
    final slot = _slots[i];
    return Container(
      key: ValueKey(_tokenDe(slot)),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.lineStrong),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: slot.cor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: slot.nomeCtrl,
                  autofocus: slot.novo,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: AppColors.text, fontSize: 15),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: t.nomeDoMercado,
                    hintStyle: TextStyle(color: AppColors.dim2),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _remover(i),
                icon: Icon(Icons.delete_outline,
                    color: AppColors.dim2, size: 20),
              ),
              if (dragIndex != null) _pinoArrastar(dragIndex),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cor in AppColors.mercadoCores)
                GestureDetector(
                  onTap: () => setState(() => slot.cor = cor),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slot.cor == cor
                            ? AppColors.text
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _togglePreferencia(i),
            child: Row(
              children: [
                Icon(slot.preferencia ? Icons.star : Icons.star_border,
                    size: 18,
                    color:
                        slot.preferencia ? AppColors.green : AppColors.dim2),
                const SizedBox(width: 6),
                Text(
                  slot.preferencia
                      ? t.preferenciaItensVemPraCa
                      : t.definirComoPreferencia,
                  style: TextStyle(
                      color:
                          slot.preferencia ? AppColors.green : AppColors.dim,
                      fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
