import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/itens_screen.dart';
import 'package:lista_app/features/listas/listas_screen.dart';
import 'package:lista_app/theme/app_colors.dart';

/// Casca principal do app: as 3 abas (Listas, Itens, Pedidos).
/// Listas e Itens já são reais; Pedidos entra no próximo passo.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          ListasScreen(),
          ItensScreen(),
          _EmBreveScreen(
            titulo: 'Pedidos',
            icone: Icons.bar_chart_rounded,
            descricao: 'Histórico das compras finalizadas e o resumo do mês.',
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

class _EmBreveScreen extends StatelessWidget {
  const _EmBreveScreen({
    required this.titulo,
    required this.icone,
    required this.descricao,
  });

  final String titulo;
  final IconData icone;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
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
              Text(descricao,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.dim, height: 1.5)),
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
      ),
    );
  }
}
