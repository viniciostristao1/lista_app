import 'package:flutter/material.dart';

/// Categorias fixas de item. Guardadas no Firestore pelo `.name` (ex: "frios").
enum Categoria {
  mercearia('Mercearia', Icons.local_grocery_store_outlined),
  hortifruti('Hortifrúti', Icons.eco_outlined),
  frios('Frios', Icons.kitchen_outlined),
  padaria('Padaria', Icons.bakery_dining_outlined),
  bebidas('Bebidas', Icons.local_drink_outlined),
  limpeza('Limpeza', Icons.cleaning_services_outlined),
  higiene('Higiene', Icons.soap_outlined),
  outros('Outros', Icons.category_outlined);

  const Categoria(this.label, this.icone);

  final String label;
  final IconData icone;

  static Categoria fromId(String? id) => Categoria.values.firstWhere(
        (c) => c.name == id,
        orElse: () => Categoria.outros,
      );
}
