import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/listas/lista_detalhe_screen.dart';
import 'package:lista_app/models/lista.dart';
import 'package:lista_app/services/auth_service.dart';
import 'package:lista_app/services/listas_repository.dart';
import 'package:lista_app/theme/app_colors.dart';

class ListasScreen extends ConsumerWidget {
  const ListasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listasAsync = ref.watch(listasAtivasProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listas'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded, color: AppColors.dim),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.onGreen,
        onPressed: () => _novaLista(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nova lista'),
      ),
      body: listasAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.green)),
        error: (_, _) => const Center(
            child: Text('Erro ao carregar.',
                style: TextStyle(color: AppColors.dim))),
        data: (listas) => listas.isEmpty
            ? _vazio()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: listas.length,
                itemBuilder: (_, i) => _cardLista(context, listas[i]),
              ),
      ),
    );
  }

  Widget _cardLista(BuildContext context, Lista lista) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ListaDetalheScreen(lista: lista)),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: AppColors.green, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lista.nome,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(_subtitulo(lista),
                          style: const TextStyle(
                              color: AppColors.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.dim2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitulo(Lista lista) {
    final d = lista.createdAt;
    if (d == null) return 'Toque para abrir';
    return 'Criada em ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Widget _vazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.checklist_rounded, size: 52, color: AppColors.dim2),
            const SizedBox(height: 16),
            const Text('Nenhuma lista ainda',
                style: TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('Toque em "Nova lista" para começar\nsua primeira compra.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.dim, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _novaLista(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Nova lista'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Compras da semana'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Criar')),
        ],
      ),
    );
    if (nome == null || nome.isEmpty) return;

    final id = await ref.read(listasRepoProvider).criar(nome);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ListaDetalheScreen(lista: Lista(id: id, nome: nome, status: 'ativa')),
      ),
    );
  }
}
