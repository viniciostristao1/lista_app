/// Como os itens da lista são ordenados (botão dinâmico no fim da lista).
enum OrdemLista {
  /// Por setor: agrupado pelas categorias na ordem que o usuário arrumou
  /// (aba Itens → Categorias), alfabético dentro de cada grupo.
  setor,

  /// Alfabética: lista corrida de A a Z.
  alfabetica,

  /// Recentes: o que entrou por último na lista aparece primeiro.
  recentes,

  /// Preço: do menor preço cadastrado pro maior (sem preço vai pro fim).
  preco;

  /// Próximo modo do ciclo (cada toque no botão avança um).
  OrdemLista get proxima => switch (this) {
        OrdemLista.setor => OrdemLista.alfabetica,
        OrdemLista.alfabetica => OrdemLista.recentes,
        OrdemLista.recentes => OrdemLista.preco,
        OrdemLista.preco => OrdemLista.setor,
      };
}
