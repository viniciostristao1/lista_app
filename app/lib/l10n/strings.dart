import '../models/categoria.dart';
import '../theme/palette.dart';

/// Idiomas suportados pelo app.
enum Idioma { pt, en, es }

/// Textos do app em Português, Inglês e Espanhol. Fonte única de tudo que é
/// "nativo" do app (não depende do usuário). Trocar o idioma = trocar a
/// instância via [stringsProvider] (ver prefs.dart).
///
/// Convenção: getters para textos fixos; métodos para os que têm valor no meio.
class AppStrings {
  const AppStrings(this.idioma);

  /// Idioma ativo: pt, en ou es.
  final Idioma idioma;

  bool get en => idioma == Idioma.en;
  bool get es => idioma == Idioma.es;

  String _s(String pt, String enTxt, String esTxt) => switch (idioma) {
        Idioma.pt => pt,
        Idioma.en => enTxt,
        Idioma.es => esTxt,
      };

  // ---------- abas / navegação ----------
  String get abaListas => _s('Listas', 'Lists', 'Listas');
  String get abaItens => _s('Itens', 'Items', 'Artículos');
  String get abaPedidos => _s('Pedidos', 'Orders', 'Pedidos');

  // ---------- genéricos ----------
  String get salvar => _s('Salvar', 'Save', 'Guardar');
  String get salvando => _s('Salvando…', 'Saving…', 'Guardando…');
  String get cancelar => _s('Cancelar', 'Cancel', 'Cancelar');
  String get excluir => _s('Excluir', 'Delete', 'Eliminar');
  String get fechar => _s('Fechar', 'Close', 'Cerrar');
  String get todos => _s('Todos', 'All', 'Todos');
  String get desfazer => _s('Desfazer', 'Undo', 'Deshacer');

  String nItens(int n) => switch (idioma) {
        Idioma.pt => '$n ${n == 1 ? 'item' : 'itens'}',
        Idioma.en => '$n ${n == 1 ? 'item' : 'items'}',
        Idioma.es => '$n ${n == 1 ? 'artículo' : 'artículos'}',
      };

  // ---------- login ----------
  String get loginTagline => _s(
      'Suas compras de mercado, organizadas\ne comparadas — sem bloco de notas.',
      'Your grocery shopping, organized\nand compared — no more notes app.',
      'Tus compras del supermercado, organizadas\ny comparadas — sin libreta.');
  String get entrarComGoogle =>
      _s('Entrar com Google', 'Sign in with Google', 'Entrar con Google');
  String get entrando => _s('Entrando…', 'Signing in…', 'Entrando…');
  String get dadosSoComVoce => _s(
      'Seus dados ficam só com você.',
      'Your data stays with you.',
      'Tus datos se quedan solo contigo.');
  String get naoConsegiuEntrar => _s(
      'Não consegui entrar', "Couldn't sign in", 'No pude entrar');
  String get semDetalhe =>
      _s('(sem detalhe)', '(no detail)', '(sin detalle)');

  // ---------- splash ----------
  String get falhaAoCarregar => _s('Falha ao carregar. Reabra o app.',
      'Failed to load. Reopen the app.', 'Error al cargar. Vuelve a abrir la app.');

  // ---------- configurações ----------
  String get configuracoes => _s('Configurações', 'Settings', 'Ajustes');
  String get tituloIdioma => _s('Idioma', 'Language', 'Idioma');
  String get tema => _s('Tema', 'Theme', 'Tema');
  String nomeTema(Tema t) => switch (t) {
        Tema.ambar => _s('Âmbar', 'Amber', 'Ámbar'),
        Tema.begeAreia => _s('Bege', 'Beige', 'Beige'),
        Tema.claroAzul => _s('Azul', 'Blue', 'Azul'),
        Tema.ameixa => _s('Ameixa', 'Plum', 'Ciruela'),
      };
  String get tamanhoDaFonte =>
      _s('Tamanho da fonte', 'Font size', 'Tamaño de letra');
  String get valeAppInteiro => _s(
      'Vale para o app inteiro.', 'Applies to the whole app.',
      'Vale para toda la app.');
  String get fonteMenor => _s('Menor', 'Smaller', 'Menor');
  String get fonteNormal => _s('Normal', 'Normal', 'Normal');
  String get fonteMaior => _s('Maior', 'Larger', 'Mayor');

  // ---------- tela Minha lista ----------
  String get minhaLista => _s('Minha lista', 'My list', 'Mi lista');
  String get copiarLista => _s('Copiar lista', 'Copy list', 'Copiar lista');
  String get sair => _s('Sair', 'Sign out', 'Salir');
  String get cadastreMercadosNaAbaItens => _s(
      'Cadastre seus mercados na aba Itens (Editar mercados).',
      'Add your stores in the Items tab (Edit stores).',
      'Registra tus tiendas en la pestaña Artículos (Editar tiendas).');
  String get semMercado => _s('Sem mercado', 'No store', 'Sin tienda');
  String get pesquiseOuAdicione =>
      _s('Pesquise ou adicione aqui', 'Search or add here', 'Busca o agrega aquí');
  String get itemJaNaLista => _s(
      'Esse item já está na lista 🙂', 'That item is already on the list 🙂',
      'Ese artículo ya está en la lista 🙂');
  String itemRemovido(String nome) => switch (idioma) {
        Idioma.pt => '"$nome" removido',
        Idioma.en => '"$nome" removed',
        Idioma.es => '"$nome" eliminado',
      };
  String get listaCopiada => _s(
      'Lista copiada! 📋 Cole onde quiser.', 'List copied! 📋 Paste anywhere.',
      '¡Lista copiada! 📋 Pégalo donde quieras.');
  String get copiarListaDe =>
      _s('Copiar lista de:', 'Copy list from:', 'Copiar lista de:');
  String get todosOsItens =>
      _s('Todos os itens', 'All items', 'Todos los artículos');
  String get economiaDe => _s('Economia de ', 'Savings of ', 'Ahorro de ');
  String total(String valor) => 'Total $valor';
  String cadastrarEAdicionar(String nome) => switch (idioma) {
        Idioma.pt => 'Cadastrar "$nome" e adicionar',
        Idioma.en => 'Add "$nome" to catalog',
        Idioma.es => 'Registrar "$nome" y agregar',
      };
  String adicionarATodos(String nome) => switch (idioma) {
        Idioma.pt => 'Adicionar "$nome" à Todos',
        Idioma.en => 'Add "$nome" to All',
        Idioma.es => 'Agregar "$nome" a Todos',
      };
  String get adicionarECadastrarItem => _s(
      'Adicionar e cadastrar item', 'Add and register item',
      'Agregar y registrar artículo');
  String cadastrarItem(String nome) => switch (idioma) {
        Idioma.pt => 'Cadastrar "$nome"',
        Idioma.en => 'Register "$nome"',
        Idioma.es => 'Registrar "$nome"',
      };
  String get ouJaNumMercado =>
      _s('Ou já num mercado:', 'Or at a specific store:', 'O ya en una tienda:');
  String get nenhumItemEncontrado => _s(
      'Nenhum item encontrado.', 'No items found.',
      'No se encontraron artículos.');
  String get jaEstaNaListaCurto => _s(
      'já está na lista', 'already on list', 'ya está en la lista');
  String get verPrecoMercado =>
      _s('Ver preço/mercado', 'Show price/store', 'Ver precio/tienda');
  String get itemSemPreco => _s(
      'Esse item ainda não tem preço.', 'This item has no price yet.',
      'Este artículo aún no tiene precio.');
  String get precoDesatualizado => _s(
      'preço desatualizado', 'price outdated', 'precio desactualizado');
  String get editarPrecosMercado => _s(
      'Editar preços/mercado', 'Edit prices/store', 'Editar precios/tienda');
  String get suaListaVazia =>
      _s('Sua lista está vazia', 'Your list is empty', 'Tu lista está vacía');
  String get useBuscaPuxarItem => _s(
      'Use a busca acima para puxar um item cadastrado.',
      'Use the search above to add a saved item.',
      'Usa la búsqueda de arriba para traer un artículo registrado.');
  String get nadaAqui => _s('Nada aqui.', 'Nothing here.', 'Nada aquí.');
  String nenhumItemEmMercado(String mercado) => switch (idioma) {
        Idioma.pt => 'Nenhum item em $mercado ainda.',
        Idioma.en => 'No items in $mercado yet.',
        Idioma.es => 'Aún no hay artículos en $mercado.',
      };
  String get finalizarCompra =>
      _s('Finalizar compra', 'Finish shopping', 'Finalizar compra');
  String finalizarMercado(String mercado) => switch (idioma) {
        Idioma.pt => 'Finalizar $mercado',
        Idioma.en => 'Finish $mercado',
        Idioma.es => 'Finalizar $mercado',
      };
  String get compraFinalizada => _s('Compra finalizada! 🛒 (veja em Pedidos)',
      'Purchase done! 🛒 (see it in Orders)',
      '¡Compra finalizada! 🛒 (míralo en Pedidos)');

  // ---------- tela Itens / comparador ----------
  String get itensComparador =>
      _s('Itens | Comparador', 'Items | Compare', 'Artículos | Comparar');
  String get buscarItem => _s('Buscar item ou cadastrar',
      'Search or register item', 'Buscar artículo o registrar');
  String get mercados => _s('Mercados', 'Stores', 'Tiendas');
  String get calculadora => _s('Calculadora', 'Calculator', 'Calculadora');
  String get categorias => _s('Categorias', 'Categories', 'Categorías');
  String get erroAoCarregar =>
      _s('Erro ao carregar.', 'Failed to load.', 'Error al cargar.');
  String get catalogoVazio =>
      _s('Catálogo vazio', 'Empty catalog', 'Catálogo vacío');
  String get catalogoVazioDica => _s(
      'Toque em "+" para cadastrar um produto\ne comparar o preço entre seus mercados.',
      'Tap "+" to add a product\nand compare prices across your stores.',
      'Toca "+" para registrar un producto\ny comparar el precio entre tus tiendas.');
  String get semPrecoToqueAdicionar => _s(
      'Sem preço cadastrado — toque para adicionar.',
      'No price yet — tap to add.',
      'Sin precio registrado — toca para agregar.');
  String economizaVs(String valor, String mercado) => switch (idioma) {
        Idioma.pt => 'economiza $valor vs $mercado',
        Idioma.en => 'saves $valor vs $mercado',
        Idioma.es => 'ahorra $valor vs $mercado',
      };
  String get segundoMaisBarato => _s(
      '2º mais barato', '2nd cheapest', '2º más barato');
  String sempreNo(String mercado) => switch (idioma) {
        Idioma.pt => 'Sempre no $mercado',
        Idioma.en => 'Always at $mercado',
        Idioma.es => 'Siempre en $mercado',
      };
  String get mercadoRemovido => _s(
      'mercado removido', 'store removed', 'tienda eliminada');
  String get recorrente => _s('recorrente', 'recurring', 'recurrente');

  // ---------- calculadora ----------
  String get calculadoraPreco =>
      _s('Calculadora de preço', 'Price calculator', 'Calculadora de precio');
  String get calculadoraIntro => _s(
      'Compare dois produtos com quantidades (peso/volume) diferentes. '
          'A calculadora diz qual sai mais barato pela mesma quantidade.',
      'Compare two products with different quantities (weight/volume). '
          'The calculator tells which is cheaper for the same amount.',
      'Compara dos productos con cantidades (peso/volumen) diferentes. '
          'La calculadora dice cuál sale más barato por la misma cantidad.');
  String get produtoA => _s('Produto A', 'Product A', 'Producto A');
  String get produtoB => _s('Produto B', 'Product B', 'Producto B');
  String get preco => _s('Preço', 'Price', 'Precio');
  String get quantidade => _s('Quantidade', 'Quantity', 'Cantidad');
  String get porUnidade => _s('Por unidade', 'Per unit', 'Por unidad');
  String get quantidadeEmUnidades => _s(
      'Quantidade em g, ml ou unidades.', 'Quantity in g, ml or units.',
      'Cantidad en g, ml o unidades.');
  String get preenchaOsDois => _s(
      'Preencha preço e quantidade dos dois.',
      'Fill in price and quantity for both.',
      'Completa precio y cantidad de los dos.');
  String vencedorMaisBarato(String vencedor, String percent) => switch (idioma) {
        Idioma.pt => '$vencedor é mais barato ($percent% mais barato)',
        Idioma.en => '$vencedor is cheaper ($percent% cheaper)',
        Idioma.es => '$vencedor es más barato ($percent% más barato)',
      };
  String comQtdBCustaria(String qtdB, String valor) => switch (idioma) {
        Idioma.pt => 'Com a quantidade do B ($qtdB), o A custaria $valor.',
        Idioma.en => 'With B\'s quantity ($qtdB), A would cost $valor.',
        Idioma.es => 'Con la cantidad del B ($qtdB), el A costaría $valor.',
      };
  String oBCusta(String valor) => switch (idioma) {
        Idioma.pt => 'O B custa $valor.',
        Idioma.en => 'B costs $valor.',
        Idioma.es => 'El B cuesta $valor.',
      };

  // ---------- pedidos ----------
  String get pedidoDesfeito => _s('Pedido desfeito — itens voltaram pra lista 🔄',
      'Order undone — items are back on the list 🔄',
      'Pedido deshecho — los artículos volvieron a la lista 🔄');
  String get excluirPedidoTitulo =>
      _s('Excluir pedido?', 'Delete order?', '¿Eliminar pedido?');
  String get excluirPedidoMsg => _s(
      'Apaga do histórico. NÃO devolve os itens para a lista.',
      'Removes it from history. Does NOT return items to the list.',
      'Lo borra del historial. NO devuelve los artículos a la lista.');
  String get pedidoExcluido =>
      _s('Pedido excluído.', 'Order deleted.', 'Pedido eliminado.');
  String emMesEconomizou(String mes) => switch (idioma) {
        Idioma.pt => 'Em $mes economizou ',
        Idioma.en => 'In $mes you saved ',
        Idioma.es => 'En $mes ahorraste ',
      };
  String economizou(String valor) => switch (idioma) {
        Idioma.pt => 'economizou $valor',
        Idioma.en => 'saved $valor',
        Idioma.es => 'ahorraste $valor',
      };
  String get excluirPedido =>
      _s('Excluir pedido', 'Delete order', 'Eliminar pedido');
  String get desfazerPedido => _s('Desfazer pedido (voltar itens à lista)',
      'Undo order (return items to the list)',
      'Deshacer pedido (devolver artículos a la lista)');
  String nenhumaCompraEm(String mes, int ano) => switch (idioma) {
        Idioma.pt => 'Nenhuma compra em $mes de $ano',
        Idioma.en => 'No purchases in $mes $ano',
        Idioma.es => 'No hubo compras en $mes de $ano',
      };
  String get finalizeUmaCompra => _s(
      'Finalize uma compra na aba Listas.',
      'Finish a purchase in the Lists tab.',
      'Finaliza una compra en la pestaña Listas.');

  // ---------- editor de produto ----------
  String get editarItem => _s('Editar item', 'Edit item', 'Editar artículo');
  String get novoItem => _s('Novo item', 'New item', 'Nuevo artículo');
  String get deUmNomeProduto => _s('Dá um nome pro produto 🙂',
      'Give the product a name 🙂', 'Ponle un nombre al producto 🙂');
  String get escolhaMercadoOuVoltar => _s(
      'Escolha um mercado — ou toque em "Voltar a comparar preços".',
      'Pick a store — or tap "Back to comparing prices".',
      'Elige una tienda — o toca "Volver a comparar precios".');
  String get escolhaMercadoRecorrente => _s(
      'Escolha em qual mercado esse item recorrente fica.',
      'Choose which store this recurring item stays at.',
      'Elige en qué tienda queda este artículo recurrente.');
  String get excluirProdutoTitulo => _s(
      'Excluir produto?', 'Delete product?', '¿Eliminar producto?');
  String get excluirProdutoMsg => _s(
      'Remove o produto do catálogo e seus preços.',
      'Removes the product from the catalog and its prices.',
      'Quita el producto del catálogo y sus precios.');
  String get compraRecorrenteNaoSai => _s(
      'Compra recorrente — não sai ao "Finalizar compra".',
      'Recurring — it stays after "Finish shopping".',
      'Compra recurrente — no sale al "Finalizar compra".');
  String get nome => _s('Nome', 'Name', 'Nombre');
  String get exNomeProduto =>
      _s('Ex: Café Pilão', 'e.g. Ground coffee', 'Ej: café molido');
  String get marcaOpcional =>
      _s('Marca (opcional)', 'Brand (optional)', 'Marca (opcional)');
  String get exMarca => _s('Ex: Pilão', 'e.g. the brand', 'Ej: la marca');
  String get pesoOpcional =>
      _s('Peso (opcional)', 'Weight (optional)', 'Peso (opcional)');
  String get exPeso => _s('Ex: 500', 'e.g. 500', 'Ej: 500');
  String get unidadeOpcional =>
      _s('Unidade (opcional)', 'Unit (optional)', 'Unidad (opcional)');
  String get exUnidade =>
      _s('Ex: g, kg, L, un', 'e.g. g, kg, L, ea', 'Ej: g, kg, L, un');
  String get categoria => _s('Categoria', 'Category', 'Categoría');
  String get observacoesOpcional => _s(
      'Observações (opcional)', 'Notes (optional)', 'Observaciones (opcional)');
  String get atualizadasEm => _s('Atualizadas em', 'Updated on', 'Actualizadas el');
  String get exObservacoes => _s(
      'Ex: marca preferida, ponto da fruta, promoção…',
      'e.g. preferred brand, ripeness, on sale…',
      'Ej: marca preferida, madurez de la fruta, promoción…');
  String get precoPorMercado =>
      _s('Preço por mercado', 'Price by store', 'Precio por tienda');
  String get cadastreMercadosPrimeiro => _s(
      'Cadastre seus mercados primeiro (aba Itens → Editar mercados).',
      'Add your stores first (Items tab → Edit stores).',
      'Registra tus tiendas primero (pestaña Artículos → Editar tiendas).');
  String get comprarSempreNumMercado => _s(
      'Comprar sempre num mercado só',
      'Always buy at one store',
      'Comprar siempre en una sola tienda');
  String get semComparacaoAnote => _s(
      'Sem comparação de preço — anote em Observações se quiser.',
      'No price comparison — jot it in Notes if you like.',
      'Sin comparación de precio — anótalo en Observaciones si quieres.');
  String get selecionarMercadoObrig => _s(
      'Selecionar mercado (obrigatório)',
      'Select store (required)',
      'Seleccionar tienda (obligatorio)');
  String get mercadoSelecionado =>
      _s('Mercado selecionado', 'Store selected', 'Tienda seleccionada');
  String get compraRecorrenteCheck => _s(
      'Compra recorrente (não sai ao finalizar)',
      'Recurring purchase (stays after finishing)',
      'Compra recurrente (no sale al finalizar)');
  String get voltarComparar => _s(
      'Voltar a comparar preços', 'Back to comparing prices',
      'Volver a comparar precios');
  String desatualizadoHa(String quando) => switch (idioma) {
        Idioma.pt => 'desatualizado ($quando)',
        Idioma.en => 'outdated ($quando)',
        Idioma.es => 'desactualizado ($quando)',
      };

  // ---------- editor de mercados ----------
  String get meusMercados => _s('Meus mercados', 'My stores', 'Mis tiendas');
  String get mercadosDescricao => _s(
      'Mercados, farmácia, shopping, Amazon… até 8. Toque numa cor pra trocar. '
          'Marque ⭐ o principal — fica ao lado de "Todos" e vem primeiro ao adicionar.',
      'Stores, pharmacy, mall, Amazon… up to 8. Tap a color to change it. '
          'Star ⭐ the main one — it sits next to "All" and comes first when adding.',
      'Tiendas, farmacia, shopping, Amazon… hasta 8. Toca un color para cambiarlo. '
          'Marca ⭐ la principal — queda al lado de "Todos" y aparece primero al agregar.');
  String get adicionarMercado =>
      _s('Adicionar mercado', 'Add store', 'Agregar tienda');
  String get salvarMercados =>
      _s('Salvar mercados', 'Save stores', 'Guardar tiendas');
  String get nomeDoMercado =>
      _s('Nome do mercado', 'Store name', 'Nombre de la tienda');
  String get preferenciaItensVemPraCa => _s(
      'Preferência (itens sem preço vêm pra cá)',
      'Preferred (items without a price go here)',
      'Preferida (los artículos sin precio vienen aquí)');
  String get definirComoPreferencia => _s(
      'Definir como preferência', 'Set as preferred', 'Definir como preferida');

  // ---------- ordenar categorias ----------
  String get ordenarCategorias =>
      _s('Ordenar categorias', 'Sort categories', 'Ordenar categorías');
  String get ordenarCategoriasDica => _s(
      'Arraste pra deixar na ordem do seu mercado — o que você pega primeiro '
          'fica em cima. Vale pra lista toda.',
      'Drag to match your store\'s layout — what you grab first goes on top. '
          'Applies to the whole list.',
      'Arrastra para dejar en el orden de tu tienda — lo que tomas primero '
          'queda arriba. Vale para toda la lista.');
  String get salvarOrdem =>
      _s('Salvar ordem', 'Save order', 'Guardar orden');

  // ---------- datas ----------
  static const _mesesAbrevPt = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];
  static const _mesesAbrevEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _mesesAbrevEs = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];
  static const _mesesNomePt = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];
  static const _mesesNomeEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _mesesNomeEs = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  /// [mes] em 1..12.
  String mesAbrev(int mes) => switch (idioma) {
        Idioma.pt => _mesesAbrevPt[mes - 1],
        Idioma.en => _mesesAbrevEn[mes - 1],
        Idioma.es => _mesesAbrevEs[mes - 1],
      };
  String mesNome(int mes) => switch (idioma) {
        Idioma.pt => _mesesNomePt[mes - 1],
        Idioma.en => _mesesNomeEn[mes - 1],
        Idioma.es => _mesesNomeEs[mes - 1],
      };

  /// "hoje" / "ontem" / "há N dias" — versão localizada de format.haDias.
  String haDias(int dias) {
    if (dias <= 0) {
      return switch (idioma) {
        Idioma.pt => 'hoje',
        Idioma.en => 'today',
        Idioma.es => 'hoy',
      };
    }
    if (dias == 1) {
      return switch (idioma) {
        Idioma.pt => 'ontem',
        Idioma.en => 'yesterday',
        Idioma.es => 'ayer',
      };
    }
    return switch (idioma) {
      Idioma.pt => 'há $dias dias',
      Idioma.en => '$dias days ago',
      Idioma.es => 'hace $dias días',
    };
  }

  // ---------- categorias ----------
  String categoria_(Categoria c) {
    switch (c) {
      case Categoria.mercearia:
        return _s('Mercearia', 'Grocery', 'Despensa');
      case Categoria.hortifruti:
        return _s('Hortifrúti', 'Produce', 'Verduras');
      case Categoria.acougue:
        return _s('Açougue', 'Butcher', 'Carnicería');
      case Categoria.frios:
        return _s('Frios', 'Deli', 'Fiambres');
      case Categoria.laticinios:
        return _s('Laticínios', 'Dairy', 'Lácteos');
      case Categoria.padaria:
        return _s('Padaria', 'Bakery', 'Panadería');
      case Categoria.congelados:
        return _s('Congelados', 'Frozen', 'Congelados');
      case Categoria.bebidas:
        return _s('Bebidas', 'Drinks', 'Bebidas');
      case Categoria.limpeza:
        return _s('Limpeza', 'Cleaning', 'Limpieza');
      case Categoria.higiene:
        return _s('Higiene', 'Toiletries', 'Higiene');
      case Categoria.pet:
        return _s('Pet', 'Pet', 'Mascotas');
      case Categoria.bebe:
        return _s('Bebê', 'Baby', 'Bebé');
      case Categoria.utilidades:
        return _s('Utilidades', 'Household', 'Utilidades');
      case Categoria.outros:
        return _s('Outros', 'Other', 'Otros');
    }
  }
}
