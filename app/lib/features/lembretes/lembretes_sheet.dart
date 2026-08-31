import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/lembrete.dart';
import '../../services/auth_service.dart';
import '../../services/lembretes_repository.dart';
import '../../services/notificacao_service.dart';
import '../../theme/app_colors.dart';
import '../../util/format.dart';

Future<void> mostrarLembretes(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _LembretesSheet(),
  );
}

class _LembretesSheet extends ConsumerStatefulWidget {
  const _LembretesSheet();
  @override
  ConsumerState<_LembretesSheet> createState() => _LembretesSheetState();
}

class _LembretesSheetState extends ConsumerState<_LembretesSheet> {
  @override
  void initState() {
    super.initState();
    NotificacaoService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).asData?.value;
    if (auth == null) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.7,
          builder: (_, scroll) => Column(
            children: [
              Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.dim2, borderRadius: BorderRadius.circular(3)))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(children: [Icon(Icons.notifications_outlined, size: 20, color: AppColors.green), const SizedBox(width: 8), Text('Lembretes', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600))]),
              ),
              Divider(color: AppColors.line, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.login, size: 48, color: AppColors.dim2),
                        const SizedBox(height: 12),
                        Text('Faça login para criar lembretes', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Entre com Google para sincronizar e receber notificações', textAlign: TextAlign.center, style: TextStyle(color: AppColors.dim, fontSize: 13)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await ref.read(authServiceProvider).signInWithGoogle();
                            } catch (_) {}
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar com Google'),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.onGreen),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final lembretesAsync = ref.watch(lembretesProvider);
    ref.listen(lembretesProvider, (prev, next) {
      final lista = next.asData?.value ?? [];
      NotificacaoService.instance.reagendarTodos(lista);
    });
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scroll) => Column(
          children: [
            Center(
              child: Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.dim2, borderRadius: BorderRadius.circular(3))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined, size: 20, color: AppColors.green),
                  const SizedBox(width: 8),
                  Text('Lembretes', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => _editar(null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Novo lembrete'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.onGreen, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.line, height: 1),
            Expanded(
              child: lembretesAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: AppColors.green)),
                error: (e, _) => Center(child: Text('$e', style: TextStyle(color: AppColors.dim))),
                data: (lista) {
                  if (lista.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.dim2),
                            const SizedBox(height: 12),
                            Text('Nenhum lembrete', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text('Crie um lembrete semanal, ex: toda sexta às 18h ver folheto', textAlign: TextAlign.center, style: TextStyle(color: AppColors.dim, fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final l = lista[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _editar(l),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                              child: Row(
                                children: [
                                  Icon(l.ativo ? Icons.notifications_active : Icons.notifications_off, size: 18, color: l.ativo ? AppColors.green : AppColors.dim2),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(l.titulo, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 14)),
                                        if (l.descricao != null && l.descricao!.isNotEmpty)
                                          Text(l.descricao!, style: TextStyle(color: AppColors.dim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Icon(Icons.schedule, size: 12, color: AppColors.dim2),
                                            const SizedBox(width: 4),
                                            Text(_textoQuando(l), style: TextStyle(color: AppColors.dim2, fontSize: 11)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                              child: Text(l.recorrencia.nome, style: TextStyle(color: AppColors.green, fontSize: 10, fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: l.ativo,
                                    activeThumbColor: AppColors.green,
                                    onChanged: (v) {
                                      ref.read(lembretesRepoProvider).toggleAtivo(l.id, v);
                                      if (v) {
                                        NotificacaoService.instance.agendar(l.copyWith(ativo: true));
                                      } else {
                                        NotificacaoService.instance.cancelar(l.id);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: AppColors.dim),
                                    onPressed: () async {
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Excluir lembrete?'),
                                          content: Text('Apagar "${l.titulo}"?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Excluir', style: TextStyle(color: AppColors.danger))),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        await ref.read(lembretesRepoProvider).excluir(l.id);
                                        await NotificacaoService.instance.cancelar(l.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _textoQuando(Lembrete l) {
    final h = l.dataHora.hour.toString().padLeft(2, '0');
    final m = l.dataHora.minute.toString().padLeft(2, '0');
    switch (l.recorrencia) {
      case Recorrencia.nenhuma:
        return '${diaMes(l.dataHora)} ${l.dataHora.year} às $h:$m';
      case Recorrencia.diaria:
        return 'Todo dia às $h:$m';
      case Recorrencia.semanal:
        const dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final d = l.diaSemana != null ? dias[(l.diaSemana! - 1) % 7] : dias[(l.dataHora.weekday - 1) % 7];
        return 'Toda $d às $h:$m';
      case Recorrencia.mensal:
        return 'Todo dia ${l.dataHora.day} às $h:$m';
    }
  }

  Future<void> _editar(Lembrete? l) async {
    final res = await showModalBottomSheet<Lembrete>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditarLembreteSheet(lembrete: l),
    );
    if (res == null) return;
    // O fluxo (escolher data → hora → salvar) pode consumir a margem: se o
    // horário escolhido passou há pouco, empurra p/ daqui 1 min para o teste
    // rápido disparar de verdade (antes, "uma vez" era descartado em silêncio
    // e semanal/mensal caíam p/ semana/mês seguinte).
    final agora = DateTime.now();
    var alvo = res;
    String? aviso;
    if (alvo.dataHora.isBefore(agora)) {
      final atraso = agora.difference(alvo.dataHora);
      if (atraso <= const Duration(minutes: 5)) {
        alvo = alvo.copyWith(dataHora: agora.add(const Duration(minutes: 1)));
        aviso = 'O horário escolhido já passou — disparei daqui 1 minuto';
      } else if (alvo.recorrencia == Recorrencia.nenhuma) {
        aviso = 'O horário já passou — esse lembrete não vai disparar';
      }
    }
    if (l == null) {
      final id = await ref.read(lembretesRepoProvider).criar(alvo);
      alvo = alvo.copyWith(id: id);
    } else {
      await ref.read(lembretesRepoProvider).salvar(alvo);
    }
    final quando = await NotificacaoService.instance.agendar(alvo);
    if (!mounted) return;
    final hh = quando?.hour.toString().padLeft(2, '0');
    final mm = quando?.minute.toString().padLeft(2, '0');
    final msg = quando != null
        ? (aviso ?? 'Lembrete agendado para ${diaMes(quando)} às $hh:$mm')
        : (aviso ?? 'Lembrete salvo (sem disparo agendado)');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (quando != null) await _pedirBateriaSePreciso();
  }

  /// Uma única vez: se o sistema está otimizando a bateria do app, os
  /// lembretes podem ser atrasados/cancelados — pede a isenção.
  Future<void> _pedirBateriaSePreciso() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool('pediuBateria') ?? false) return;
    final otimizada = await NotificacaoService.instance.bateriaOtimizada();
    if (otimizada != true || !mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Lembretes na hora certa'),
        content: const Text('Para os lembretes tocarem mesmo com o app fechado, permita que o Save List ignore a otimização de bateria.\n\nSem isso, alguns aparelhos (Samsung, Xiaomi etc.) seguram ou cancelam o alarme.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false), child: const Text('Agora não')),
          FilledButton(onPressed: () => Navigator.pop(dCtx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.onGreen), child: const Text('Permitir')),
        ],
      ),
    );
    await p.setBool('pediuBateria', true);
    if (ok == true) await NotificacaoService.instance.pedirIgnorarBateria();
  }
}

extension _Copy on Lembrete {
  Lembrete copyWith({String? id, String? titulo, String? descricao, DateTime? dataHora, Recorrencia? recorrencia, int? diaSemana, bool? ativo}) =>
      Lembrete(id: id ?? this.id, titulo: titulo ?? this.titulo, descricao: descricao ?? this.descricao, dataHora: dataHora ?? this.dataHora, recorrencia: recorrencia ?? this.recorrencia, diaSemana: diaSemana ?? this.diaSemana, ativo: ativo ?? this.ativo, createdAt: createdAt);
}

class _EditarLembreteSheet extends StatefulWidget {
  const _EditarLembreteSheet({this.lembrete});
  final Lembrete? lembrete;
  @override
  State<_EditarLembreteSheet> createState() => _EditarLembreteSheetState();
}

class _EditarLembreteSheetState extends State<_EditarLembreteSheet> {
  late final TextEditingController _titulo;
  late final TextEditingController _desc;
  late DateTime _dataHora;
  late Recorrencia _recorrencia;
  int? _diaSemana;

  @override
  void initState() {
    super.initState();
    final l = widget.lembrete;
    _titulo = TextEditingController(text: l?.titulo ?? '');
    _desc = TextEditingController(text: l?.descricao ?? '');
    _dataHora = l?.dataHora ?? DateTime.now().add(const Duration(hours: 1));
    _recorrencia = l?.recorrencia ?? Recorrencia.semanal;
    _diaSemana = l?.diaSemana ?? _dataHora.weekday;
  }

  @override
  void dispose() {
    _titulo.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _escolherDataHora() async {
    final d = await showDatePicker(context: context, initialDate: _dataHora, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365 * 2)));
    if (d == null) return;
    if (!mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dataHora));
    if (t == null) return;
    setState(() => _dataHora = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.lembrete != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: AppColors.dim2, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 14),
              Text(editando ? 'Editar lembrete' : 'Novo lembrete', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              TextField(controller: _titulo, textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: 'Título *', hintText: 'Ex: Ver folheto Atacadão', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true, filled: true, fillColor: AppColors.bg), style: TextStyle(color: AppColors.text)),
              const SizedBox(height: 12),
              TextField(controller: _desc, decoration: InputDecoration(labelText: 'Descrição (opcional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), isDense: true, filled: true, fillColor: AppColors.bg), style: TextStyle(color: AppColors.text)),
              const SizedBox(height: 12),
              InkWell(
                onTap: _escolherDataHora,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppColors.green, size: 18),
                      const SizedBox(width: 8),
                      Text('${diaMes(_dataHora)} ${ _dataHora.year} • ${ _dataHora.hour.toString().padLeft(2,'0')}:${_dataHora.minute.toString().padLeft(2,'0')}', style: TextStyle(color: AppColors.text, fontSize: 14)),
                      const Spacer(),
                      Text('Alterar', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Repetir', style: TextStyle(color: AppColors.dim, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in Recorrencia.values)
                    ChoiceChip(
                      label: Text(r.nome),
                      selected: _recorrencia == r,
                      onSelected: (v) { if (v) setState(() => _recorrencia = r); },
                      selectedColor: AppColors.green,
                      labelStyle: TextStyle(color: _recorrencia == r ? AppColors.onGreen : AppColors.dim, fontWeight: FontWeight.w600),
                      backgroundColor: AppColors.bg,
                      side: BorderSide(color: _recorrencia == r ? AppColors.green : AppColors.line),
                    ),
                ],
              ),
              if (_recorrencia == Recorrencia.semanal) ...[
                const SizedBox(height: 10),
                Text('Dia da semana', style: TextStyle(color: AppColors.dim, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (var i = 1; i <= 7; i++)
                      ChoiceChip(
                        label: Text(['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'][i-1]),
                        selected: _diaSemana == i,
                        onSelected: (v) { if (v) setState(() => _diaSemana = i); },
                        selectedColor: AppColors.green,
                        labelStyle: TextStyle(color: _diaSemana == i ? AppColors.onGreen : AppColors.dim, fontSize: 12),
                        backgroundColor: AppColors.bg,
                        side: BorderSide(color: _diaSemana == i ? AppColors.green : AppColors.line),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_titulo.text.trim().isEmpty) return;
                    final l = widget.lembrete;
                    final novo = Lembrete(
                      id: l?.id ?? '',
                      titulo: _titulo.text.trim(),
                      descricao: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
                      dataHora: _dataHora,
                      recorrencia: _recorrencia,
                      diaSemana: _recorrencia == Recorrencia.semanal ? _diaSemana : null,
                      ativo: l?.ativo ?? true,
                      createdAt: l?.createdAt,
                    );
                    Navigator.pop(context, novo);
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.onGreen, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(widget.lembrete != null ? 'Salvar' : 'Criar lembrete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
