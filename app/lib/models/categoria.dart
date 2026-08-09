import 'package:flutter/material.dart';

/// Categorias fixas de item (lista abrangente de supermercado).
/// Guardadas no Firestore pelo `.name` (ex: "frios"). A ordem aqui é a ordem
/// em que aparecem agrupadas nas telas.
enum Categoria {
  mercearia('Mercearia', Icons.local_grocery_store_outlined),
  hortifruti('Hortifrúti', Icons.eco_outlined),
  acougue('Açougue', Icons.restaurant_outlined),
  frios('Frios', Icons.kitchen_outlined),
  laticinios('Laticínios', Icons.egg_outlined),
  padaria('Padaria', Icons.bakery_dining_outlined),
  congelados('Congelados', Icons.ac_unit),
  bebidas('Bebidas', Icons.local_drink_outlined),
  limpeza('Limpeza', Icons.cleaning_services_outlined),
  higiene('Higiene', Icons.soap_outlined),
  pet('Pet', Icons.pets),
  bebe('Bebê', Icons.child_friendly),
  utilidades('Utilidades', Icons.handyman_outlined),
  outros('Outros', Icons.category_outlined);

  const Categoria(this.label, this.icone);

  final String label;
  final IconData icone;

  static Categoria fromId(String? id) => Categoria.values.firstWhere(
        (c) => c.name == id,
        orElse: () => Categoria.outros,
      );
}
