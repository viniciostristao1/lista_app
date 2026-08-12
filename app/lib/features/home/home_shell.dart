import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/itens_screen.dart';
import 'package:lista_app/features/listas/listas_screen.dart';
import 'package:lista_app/features/pedidos/pedidos_screen.dart';
import 'package:lista_app/services/prefs.dart';

/// Casca principal do app: as 3 abas (Listas, Itens, Pedidos).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          ListasScreen(),
          ItensScreen(),
          PedidosScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist_rounded),
            label: t.abaListas,
          ),
          NavigationDestination(
            icon: const Icon(Icons.sell_outlined),
            selectedIcon: const Icon(Icons.sell_rounded),
            label: t.abaItens,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(Icons.bar_chart_rounded),
            label: t.abaPedidos,
          ),
        ],
      ),
    );
  }
}
