import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lista_app/features/itens/itens_screen.dart';
import 'package:lista_app/features/listas/listas_screen.dart';
import 'package:lista_app/features/pedidos/pedidos_screen.dart';
import 'package:lista_app/services/prefs.dart';

/// Casca principal do app: as 3 abas (Listas, Itens, Pedidos).
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final index = ref.watch(homeIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: const [
          ListasScreen(),
          ItensScreen(),
          PedidosScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeIndexProvider.notifier).definir(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart_rounded),
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
