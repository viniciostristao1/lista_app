import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

/// Casca principal do app: as 3 abas (Listas, Itens, Pedidos).
/// Os conteúdos são placeholders por enquanto — cada aba vira uma feature real
/// nos próximos passos da Fase 1.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _titulos = ['Listas', 'Itens', 'Pedidos'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titulos[_index]),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded, color: AppColors.dim),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _EmBreve(
            icone: Icons.checklist_rounded,
            titulo: 'Listas',
            descricao:
                'Aqui vão suas listas de compras, com total ao vivo e a\nlegenda dos mercados no topo.',
          ),
          _EmBreve(
            icone: Icons.sell_outlined,
            titulo: 'Itens',
            descricao:
                'Seu catálogo: cada produto com o preço em cada mercado\n— o comparador.',
          ),
          _EmBreve(
            icone: Icons.bar_chart_rounded,
            titulo: 'Pedidos',
            descricao:
                'Histórico das compras finalizadas e o resumo do mês.',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Listas',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell_rounded),
            label: 'Itens',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Pedidos',
          ),
        ],
      ),
    );
  }
}

class _EmBreve extends StatelessWidget {
  const _EmBreve({
    required this.icone,
    required this.titulo,
    required this.descricao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppColors.dim2),
            const SizedBox(height: 16),
            Text(titulo,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.dim, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: const Text('Em construção',
                  style: TextStyle(color: AppColors.dim2, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
