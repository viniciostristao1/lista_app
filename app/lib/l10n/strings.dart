import '../models/categoria.dart';
import '../theme/palette.dart';

/// Textos do app em Português e Inglês. Fonte única de tudo que é "nativo" do
/// app (não depende do usuário). Trocar o idioma = trocar a instância via
/// [stringsProvider] (ver prefs.dart). `en == true` → inglês.
///
/// Convenção: getters para textos fixos; métodos para os que têm valor no meio.
class AppStrings {
  const AppStrings(this.en);

  /// true = inglês; false = português.
  final bool en;

  String _s(String pt, String enTxt) => en ? enTxt : pt;

  // ---------- abas / navegação ----------
  String get abaListas => _s('Listas', 'Lists');
  String get abaItens => _s('Itens', 'Items');
  String get abaPedidos => _s('Pedidos', 'Orders');

  // ---------- genéricos ----------
  String get salvar => _s('Salvar', 'Save');
  String get salvando => _s('Salvando…', 'Saving…');
  String get cancelar => _s('Cancelar', 'Cancel');
  String get excluir => _s('Excluir', 'Delete');
  String get fechar => _s('Fechar', 'Close');
  String get todos => _s('Todos', 'All');
  String get desfazer => _s('Desfazer', 'Undo');

  String nItens(int n) => en
      ? '$n ${n == 1 ? 'item' : 'items'}'
      : '$n ${n == 1 ? 'item' : 'itens'}';

  // ---------- login ----------
  String get loginTagline => _s(
      'Suas compras de mercado, organizadas\ne comparadas — sem bloco de notas.',
      'Your grocery shopping, organized\nand compared — no more notes app.');
  String get entrarComGoogle => _s('Entrar com Google', 'Sign in with Google');
  String get entrando => _s('Entrando…', 'Signing in…');
  String get dadosSoComVoce =>
      _s('Seus dados ficam só com você.', 'Your data stays with you.');
  String get naoConsegiuEntrar => _s('Não consegui entrar', "Couldn't sign in");
  String get semDetalhe => _s('(sem detalhe)', '(no detail)');

  // ---------- splash ----------
  String get falhaAoCarregar =>
      _s('Falha ao carregar. Reabra o app.', 'Failed to load. Reopen the app.');

  // ---------- configurações ----------
  String get configuracoes => _s('Configurações', 'Settings');
  String get idioma => _s('Idioma', 'Language');
  String get tema => _s('Tema', 'Theme');
  String nomeTema(Tema t) => switch (t) {
        Tema.ambar => _s('Âmbar', 'Amber'),
        Tema.begeAreia => _s('Bege', 'Beige'),
        Tema.claroAzul => _s('Azul', 'Blue'),
        Tema.ameixa => _s('Ameixa', 'Plum'),
      };
  String get tamanhoDaFonte => _s('Tamanho da fonte', 'Font size');
  String get valeAppInteiro =>
      _s('Vale para o app inteiro.', 'Applies to the whole app.');
  String get fonteMenor => _s('Menor', 'Smaller');
  String get fonteNormal => _s('Normal', 'Normal');
  String get fonteMaior => _s('Maior', 'Larger');

  // ---------- tela Minha lista ----------
  String get minhaLista => _s('Minha lista', 'My list');
  String get copiarLista => _s('Copiar lista', 'Copy list');
  String get sair => _s('Sair', 'Sign out');
  String get cadastreMercadosNaAbaItens => _s(
      'Cadastre seus mercados na aba Itens (Editar mercados).',
      'Add your stores in the Items tab (Edit stores).');
  String get semMercado => _s('Sem mercado', 'No store');
  String get pesquiseOuAdicione =>
      _s('Pesquise ou adicione aqui', 'Search or add here');
  String get itemJaNaLista =>
      _s('Esse item já está na lista 🙂', 'That item is already on the list 🙂');
  String itemRemovido(String nome) =>
      en ? '"$nome" removed' : '"$nome" removido';
  String get listaCopiada => _s(
      'Lista copiada! 📋 Cole onde quiser.', 'List copied! 📋 Paste anywhere.');
  String get copiarListaDe => _s('Copiar lista de:', 'Copy list from:');
  String get todosOsItens => _s('Todos os itens', 'All items');
  String get economiaDe => _s('Economia de ', 'Savings of ');
  String total(String valor) => 'Total $valor';
  String cadastrarEAdicionar(String nome) => en
      ? 'Add "$nome" to catalog'
      : 'Cadastrar "$nome" e adicionar';
  String adicionarATodos(String nome) =>
      en ? 'Add "$nome" to All' : 'Adicionar "$nome" à Todos';
  String get adicionarECadastrarItem =>
      _s('Adicionar e cadastrar item', 'Add and register item');
  String cadastrarItem(String nome) =>
      en ? 'Register "$nome"' : 'Cadastrar "$nome"';
  String get ouJaNumMercado => _s('Ou já num mercado:', 'Or at a specific store:');
  String get nenhumItemEncontrado =>
      _s('Nenhum item encontrado.', 'No items found.');
  String get jaEstaNaListaCurto => _s('já está na lista', 'already on list');
  String get verPrecoMercado => _s('Ver preço/mercado', 'Show price/store');
  String get itemSemPreco =>
      _s('Esse item ainda não tem preço.', 'This item has no price yet.');
  String get precoDesatualizado => _s('preço desatualizado', 'price outdated');
  String get editarPrecosMercado =>
      _s('Editar preços/mercado', 'Edit prices/store');
  String get suaListaVazia => _s('Sua lista está vazia', 'Your list is empty');
  String get useBuscaPuxarItem => _s(
      'Use a busca acima para puxar um item cadastrado.',
      'Use the search above to add a saved item.');
  String get nadaAqui => _s('Nada aqui.', 'Nothing here.');
  String nenhumItemEmMercado(String mercado) =>
      en ? 'No items in $mercado yet.' : 'Nenhum item em $mercado ainda.';
  String get finalizarCompra => _s('Finalizar compra', 'Finish shopping');
  String finalizarMercado(String mercado) =>
      en ? 'Finish $mercado' : 'Finalizar $mercado';
  String get compraFinalizada => _s('Compra finalizada! 🛒 (veja em Pedidos)',
      'Purchase done! 🛒 (see it in Orders)');

  // ---------- tela Itens / comparador ----------
  String get itensComparador => _s('Itens | Comparador', 'Items | Compare');
  String get buscarItem => _s('Buscar item…', 'Search item…');
  String get mercados => _s('Mercados', 'Stores');
  String get calculadora => _s('Calculadora', 'Calculator');
  String get categorias => _s('Categorias', 'Categories');
  String get erroAoCarregar => _s('Erro ao carregar.', 'Failed to load.');
  String get catalogoVazio => _s('Catálogo vazio', 'Empty catalog');
  String get catalogoVazioDica => _s(
      'Toque em "+" para cadastrar um produto\ne comparar o preço entre seus mercados.',
      'Tap "+" to add a product\nand compare prices across your stores.');
  String get semPrecoToqueAdicionar => _s(
      'Sem preço cadastrado — toque para adicionar.', 'No price yet — tap to add.');
  String economizaVs(String valor, String mercado) =>
      en ? 'saves $valor vs $mercado' : 'economiza $valor vs $mercado';
  String get segundoMaisBarato => _s('2º mais barato', '2nd cheapest');
  String sempreNo(String mercado) =>
      en ? 'Always at $mercado' : 'Sempre no $mercado';
  String get mercadoRemovido => _s('mercado removido', 'store removed');
  String get recorrente => _s('recorrente', 'recurring');

  // ---------- calculadora ----------
  String get calculadoraPreco => _s('Calculadora de preço', 'Price calculator');
  String get calculadoraIntro => _s(
      'Compare dois produtos com quantidades (peso/volume) diferentes. '
          'A calculadora diz qual sai mais barato pela mesma quantidade.',
      'Compare two products with different quantities (weight/volume). '
          'The calculator tells which is cheaper for the same amount.');
  String get produtoA => _s('Produto A', 'Product A');
  String get produtoB => _s('Produto B', 'Product B');
  String get preco => _s('Preço', 'Price');
  String get quantidade => _s('Quantidade', 'Quantity');
  String get porUnidade => _s('Por unidade', 'Per unit');
  String get quantidadeEmUnidades =>
      _s('Quantidade em g, ml ou unidades.', 'Quantity in g, ml or units.');
  String get preenchaOsDois =>
      _s('Preencha preço e quantidade dos dois.', 'Fill in price and quantity for both.');
  String vencedorMaisBarato(String vencedor, String percent) => en
      ? '$vencedor is cheaper ($percent% cheaper)'
      : '$vencedor é mais barato ($percent% mais barato)';
  String comQtdBCustaria(String qtdB, String valor) => en
      ? 'With B\'s quantity ($qtdB), A would cost $valor.'
      : 'Com a quantidade do B ($qtdB), o A custaria $valor.';
  String oBCusta(String valor) =>
      en ? 'B costs $valor.' : 'O B custa $valor.';

  // ---------- pedidos ----------
  String get pedidoDesfeito => _s('Pedido desfeito — itens voltaram pra lista 🔄',
      'Order undone — items are back on the list 🔄');
  String get excluirPedidoTitulo => _s('Excluir pedido?', 'Delete order?');
  String get excluirPedidoMsg => _s(
      'Apaga do histórico. NÃO devolve os itens para a lista.',
      'Removes it from history. Does NOT return items to the list.');
  String get pedidoExcluido => _s('Pedido excluído.', 'Order deleted.');
  String emMesEconomizou(String mes) =>
      en ? 'In $mes you saved ' : 'Em $mes economizou ';
  String economizou(String valor) =>
      en ? 'saved $valor' : 'economizou $valor';
  String get excluirPedido => _s('Excluir pedido', 'Delete order');
  String get desfazerPedido => _s('Desfazer pedido (voltar itens à lista)',
      'Undo order (return items to the list)');
  String nenhumaCompraEm(String mes, int ano) =>
      en ? 'No purchases in $mes $ano' : 'Nenhuma compra em $mes de $ano';
  String get finalizeUmaCompra =>
      _s('Finalize uma compra na aba Listas.', 'Finish a purchase in the Lists tab.');

  // ---------- editor de produto ----------
  String get editarItem => _s('Editar item', 'Edit item');
  String get novoItem => _s('Novo item', 'New item');
  String get deUmNomeProduto => _s('Dá um nome pro produto 🙂', 'Give the product a name 🙂');
  String get escolhaMercadoOuVoltar => _s(
      'Escolha um mercado — ou toque em "Voltar a comparar preços".',
      'Pick a store — or tap "Back to comparing prices".');
  String get escolhaMercadoRecorrente => _s(
      'Escolha em qual mercado esse item recorrente fica.',
      'Choose which store this recurring item stays at.');
  String get excluirProdutoTitulo => _s('Excluir produto?', 'Delete product?');
  String get excluirProdutoMsg => _s(
      'Remove o produto do catálogo e seus preços.',
      'Removes the product from the catalog and its prices.');
  String get compraRecorrenteNaoSai => _s(
      'Compra recorrente — não sai ao "Finalizar compra".',
      'Recurring — it stays after "Finish shopping".');
  String get nome => _s('Nome', 'Name');
  String get exNomeProduto => _s('Ex: Café Pilão', 'e.g. Ground coffee');
  String get marcaOpcional => _s('Marca (opcional)', 'Brand (optional)');
  String get exMarca => _s('Ex: Pilão', 'e.g. the brand');
  String get pesoOpcional => _s('Peso (opcional)', 'Weight (optional)');
  String get exPeso => _s('Ex: 500', 'e.g. 500');
  String get unidadeOpcional => _s('Unidade (opcional)', 'Unit (optional)');
  String get exUnidade => _s('Ex: g, kg, L, un', 'e.g. g, kg, L, ea');
  String get categoria => _s('Categoria', 'Category');
  String get observacoesOpcional =>
      _s('Observações (opcional)', 'Notes (optional)');
  String get exObservacoes => _s(
      'Ex: marca preferida, ponto da fruta, promoção…',
      'e.g. preferred brand, ripeness, on sale…');
  String get precoPorMercado => _s('Preço por mercado', 'Price by store');
  String get cadastreMercadosPrimeiro => _s(
      'Cadastre seus mercados primeiro (aba Itens → Editar mercados).',
      'Add your stores first (Items tab → Edit stores).');
  String get comprarSempreNumMercado =>
      _s('Comprar sempre num mercado só', 'Always buy at one store');
  String get semComparacaoAnote => _s(
      'Sem comparação de preço — anote em Observações se quiser.',
      'No price comparison — jot it in Notes if you like.');
  String get selecionarMercadoObrig =>
      _s('Selecionar mercado (obrigatório)', 'Select store (required)');
  String get mercadoSelecionado => _s('Mercado selecionado', 'Store selected');
  String get compraRecorrenteCheck => _s(
      'Compra recorrente (não sai ao finalizar)',
      'Recurring purchase (stays after finishing)');
  String get voltarComparar =>
      _s('Voltar a comparar preços', 'Back to comparing prices');
  String desatualizadoHa(String quando) =>
      en ? 'outdated ($quando)' : 'desatualizado ($quando)';

  // ---------- editor de mercados ----------
  String get meusMercados => _s('Meus mercados', 'My stores');
  String get mercadosDescricao => _s(
      'Mercados, farmácia, shopping, Amazon… até 8. Toque numa cor pra trocar. '
          'Marque ⭐ o principal — fica ao lado de "Todos" e vem primeiro ao adicionar.',
      'Stores, pharmacy, mall, Amazon… up to 8. Tap a color to change it. '
          'Star ⭐ the main one — it sits next to "All" and comes first when adding.');
  String get adicionarMercado => _s('Adicionar mercado', 'Add store');
  String get salvarMercados => _s('Salvar mercados', 'Save stores');
  String get nomeDoMercado => _s('Nome do mercado', 'Store name');
  String get preferenciaItensVemPraCa => _s(
      'Preferência (itens sem preço vêm pra cá)',
      'Preferred (items without a price go here)');
  String get definirComoPreferencia =>
      _s('Definir como preferência', 'Set as preferred');

  // ---------- ordenar categorias ----------
  String get ordenarCategorias => _s('Ordenar categorias', 'Sort categories');
  String get ordenarCategoriasDica => _s(
      'Arraste pra deixar na ordem do seu mercado — o que você pega primeiro '
          'fica em cima. Vale pra lista toda.',
      'Drag to match your store\'s layout — what you grab first goes on top. '
          'Applies to the whole list.');
  String get salvarOrdem => _s('Salvar ordem', 'Save order');

  // ---------- datas ----------
  static const _mesesAbrevPt = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];
  static const _mesesAbrevEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _mesesNomePt = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _mesesNomeEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// [mes] em 1..12.
  String mesAbrev(int mes) =>
      (en ? _mesesAbrevEn : _mesesAbrevPt)[mes - 1];
  String mesNome(int mes) => (en ? _mesesNomeEn : _mesesNomePt)[mes - 1];

  /// "hoje" / "ontem" / "há N dias" — versão localizada de format.haDias.
  String haDias(int dias) {
    if (dias <= 0) return en ? 'today' : 'hoje';
    if (dias == 1) return en ? 'yesterday' : 'ontem';
    return en ? '$dias days ago' : 'há $dias dias';
  }

  // ---------- categorias ----------
  String categoria_(Categoria c) {
    switch (c) {
      case Categoria.mercearia:
        return _s('Mercearia', 'Grocery');
      case Categoria.hortifruti:
        return _s('Hortifrúti', 'Produce');
      case Categoria.acougue:
        return _s('Açougue', 'Butcher');
      case Categoria.frios:
        return _s('Frios', 'Deli');
      case Categoria.laticinios:
        return _s('Laticínios', 'Dairy');
      case Categoria.padaria:
        return _s('Padaria', 'Bakery');
      case Categoria.congelados:
        return _s('Congelados', 'Frozen');
      case Categoria.bebidas:
        return _s('Bebidas', 'Drinks');
      case Categoria.limpeza:
        return _s('Limpeza', 'Cleaning');
      case Categoria.higiene:
        return _s('Higiene', 'Toiletries');
      case Categoria.pet:
        return _s('Pet', 'Pet');
      case Categoria.bebe:
        return _s('Bebê', 'Baby');
      case Categoria.utilidades:
        return _s('Utilidades', 'Household');
      case Categoria.outros:
        return _s('Outros', 'Other');
    }
  }
}
