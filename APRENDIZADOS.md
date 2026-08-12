# Aprendizados & Diário — Lista App

Registro do que aprendemos e do que fizemos, pra **não repetir erros** e pra
qualquer sessão futura (ou pessoa) entender o caminho.

## Como usar (o fluxo)
- **Ao fim de cada bloco significativo:** adicionar 1 entrada no Diário + qualquer
  lição nova em Aprendizados → **commit e push**.
- **Diário** = o que foi feito, curto e datado.
- **Aprendizados** = lições reusáveis (principalmente os "gotchas" que custaram tempo).
- **Decisões de produto** = o "porquê" das escolhas, pra não re-discutir.

---

## Diário

### 2026-08-12 — 4 cores novas + preço "$" na lista + "Por unidade" + botões alinhados
- **Paleta de mercados 8→12** (`app_colors.dart`): bege, vermelho forte, marrom, verde
  escuro. **Gotcha:** o seletor de cores em `mercados_editor_sheet.dart` era um `Row`
  reto (cabia 8, estouraria com 12) → trocado por **`Wrap`** (quebra em 2 linhas).
  Ao acrescentar cor no futuro, conferir esse `Wrap`.
- **Aba Listas — preço vira "$" alinhado** (`listas_screen.dart`): novo `_slotPreco` +
  estado `Set<String> _precoVisivel`. Por padrão mostra `Icons.attach_money` (coluna
  alinhada); toca → revela o valor; toca de novo → esconde. Item **dedicado** (mercado
  fixo, sem comparação) mostra o **nome do mercado** no lugar do "$". Elimina a
  desalinhamento entre item com preço e item sem.
- **Calculadora — 3ª coluna "Por unidade"** (`calculadora_screen.dart`): read-only,
  `preço ÷ quantidade`, à direita de Quantidade. `_fmtUnidade` usa 2 casas p/ ≥1 e até 4
  casas (sem zeros à toa) p/ valores pequenos (R$/g, R$/ml). Label de Quantidade encurtado
  ("(g/ml/un)" virou nota abaixo) pra caber 3 colunas.
- **Aba Itens — botões alinhados com "Buscar item"**: `SingleChildScrollView` horizontal
  → `Row` com 3 `Expanded` (dividem a largura toda, bordas na margem 16). `_boxEditar`
  com padding menor (12→8), conteúdo centralizado e label `Flexible`+ellipsis (não estoura).
- `flutter analyze lib/` limpo.

### 2026-07-23/24 — Setup + Fase 1
- Estrutura do projeto, repositório privado no GitHub, Flutter 3.44.7 na VPS.
- Firebase conectado (Android): `firebase_options.dart` + `google-services.json` +
  plugin no Gradle.
- **Fase 1 (aba Listas) completa:** criar/renomear/excluir listas, adicionar item com
  autocomplete do histórico, marcar comprado, total ao vivo, editor de mercados,
  finalizar. Tudo no Firestore com sync/offline. Regras de segurança publicadas.
- Pipeline de **APK na nuvem** (GitHub Actions) + releases.

### 2026-07-25 — Login funcionando + aba Itens
- **Saga do login resolvida** (ver Aprendizados 1–3). App instalado no celular e
  **login com Google funcionando** de ponta a ponta.
- **Assinatura fixa** (keystore de upload) configurada → updates instalam por cima.
- **Aba Itens:** catálogo + comparador. Produto ganhou marca/tamanho/unidade; preço
  por mercado com data; alerta vermelho de "desatualizado" (>30 dias); destaque do
  MENOR + "economia vs 2º mais barato".
- **Próximo:** ligar a economia na aba Listas (menor preço + economia + % geral) e
  terminar a aba Pedidos (histórico + resumo do mês).

### 2026-07-25 (cont.) — Aba Listas repensada: "lista rápida" de mercado
- Listas virou **uma lista única** (a compra atual) — removido o gerenciar-várias.
- Adicionar item = **buscar (🔍) no catálogo e puxar**; não se digita preço na lista
  (o preço vem da aba Itens).
- Destaque da lista = **economia** (Σ do 2º−menor) + **percentual**; "estimado" e nº
  de itens como linha secundária.
- Aba **Itens em ordem alfabética**.
- Removidos `lista_detalhe_screen.dart` e `add_item_sheet.dart`.
- **Pendente:** aba **Pedidos** (o usuário quer repensá-la; será mais complexa).

### 2026-07-25 (cont.) — Filtro por mercado na aba Listas
- Legenda virou **barra de filtro**: chip "Todos" + um por mercado. Tocar num mercado
  mostra só os itens em que ele é o mais barato. Mantido o "editar" (✎).
- Economia/estimado recomputam para o subconjunto visível; "Finalizar" usa a lista toda.
- Estética: fonte do valor da economia reduzida (30 → 23).

### 2026-07-25 (cont.) — Finalizar por mercado + editar mercados na Itens + estética
- **Finalizar** respeita o filtro: remove só os itens do mercado filtrado
  (botão "Finalizar {mercado}"); em "Todos", remove a lista toda.
- **Editar mercados** movido pra aba **Itens** (caixinha estreita); ✎ saiu da Listas.
- Economia mais compacta ("vs a 2ª opção" ao lado do %).
- Itens: **marca/tamanho/unidade ao lado do nome** (card mais estreito).
- Listas: menos espaço entre categorias.
- **PRÓXIMO:** "editar categorias" (tornar as categorias editáveis) ao lado de
  "editar mercados" na aba Itens.

### 2026-07-25 (cont.) — Polimentos + categorias fixas + bug de categoria
- Itens: FAB só "+"; economia nomeia o 2º mercado ("vs {Mercado}").
- Listas: busca "Buscar item cadastrado ou Novo"; caixa **Economia** compacta
  (só "Economia" + "Total R$X · N itens" ao lado, "Estimado" virou "Total").
- **Bug corrigido:** categoria/nome do item na lista agora vêm do **produto
  (catálogo)**, não do retrato salvo no item → editar na aba Itens reflete na hora.
- **Decisão:** categorias = **lista fixa ampliada (13)**; NÃO faremos "editar
  categorias" (complexidade > ganho). Itens fica só com "Editar mercados".

### 2026-07-25 (cont.) — 3 correções
- Editor de produto: **Categoria** movida pro final (abaixo dos preços/mercados).
- **Exclusão inteligente na Listas:** ao excluir um item cujo produto **não tem
  preço** (novo/criado na hora), o produto some do catálogo junto; se tem preço
  (cadastrado), permanece na aba Itens.
- **Bug:** ao **excluir um mercado**, agora remove os preços dele de todos os
  produtos (`ProdutosRepository.removerMercadoDeTodos`).

### 2026-07-26 — 5 features: fixar, copiar, data no card, observações, economia 1 linha
- Produto ganhou **fixado** (pino) + **observações**.
- Editor: **pino** no AppBar (fixa/desfixa) + campo **Observações**; categoria por último.
- **Fixado não sai ao "Finalizar compra"** (só por exclusão manual / da aba Itens);
  `removiveis = visíveis não-fixados`.
- Itens: **data dd/mm** da última atualização à direita (antes da categoria, vermelha
  se >30d); pílulas de preço sem a linha de data (mais estreitas); pino nos fixados.
- Listas: caixa **Economia** numa linha ("Economia de R$X (Y%)" + Total/itens à direita).
- Listas: **Copiar lista** (ícone exportar no topo) → escolhe mercado → copia "• item"
  pra área de transferência (`Clipboard`).

### 2026-07-26 (cont.) — quantidade, aviso duplicado, calculadora, logo, fix do fixar
- Listas: **stepper − N +** de quantidade em cada item (`setQuantidade`); buscar um
  item que já está na lista mostra **"já está na lista"** (não duplica).
- Itens: **data + categoria na mesma linha** à direita; **pino** à esquerda da data
  quando fixado.
- **FIX do fixar:** o pino agora **salva na hora** (`setFixado`) — antes dependia de
  apertar Salvar e por isso o item "fixado" sumia no finalizar.
- **Calculadora** de preço por quantidade (pesos diferentes) — botão ao lado de
  Editar mercados na aba Itens.
- **Logo novo:** dois "V" azuis (duplo-check), vetorial próprio (`widgets/logo_lista.dart`
  via CustomPainter), na tela de login. **Pendente:** ícone do launcher (tela inicial).

### 2026-07-26 (cont.) — Login migrado pro Google NATIVO
- `signInWithProvider` (navegador) deu "Failed to generate/retrieve public encryption
  key for Generic IDP flow" após um logout. Fluxo frágil (ver Aprendizado 9).
- Migrado pra **google_sign_in 7.x nativo** + Web client ID como `serverClientId`.
  Re-adicionado o pacote `google_sign_in`. Auth provisionada + SHA-1 já registrados.

### 2026-07-26 (cont.) — Aba PEDIDOS + peso + logout rápido
- Label "Tamanho" → **"Peso"**.
- **Logout lento (~7s) corrigido:** `_auth.signOut()` roda **primeiro** (tela muda na
  hora); o `GoogleSignIn.signOut()` roda depois sem travar a UI.
- **Aba Pedidos construída** 🎉: finalizar compra agora **arquiva um pedido** (data,
  mercado, total, economia, retrato dos itens) em vez de só apagar. Tela: filtro por
  mercado (Todos + chips), **resumo do mês** (economia + total, filtrado), lista de
  pedidos, e **desfazer pedido** (devolve os itens à lista atual + apaga o pedido).
  Model `Pedido`/`PedidoItem`, `PedidosRepository`, coleção `users/{uid}/pedidos`.

### 2026-07-26 (cont.) — split por mercado, fixar→lista, card mês, logo+ícone
- Finalizar em **"Todos"** agora **separa por mercado** (1 pedido por mercado mais
  barato; itens sem preço vão num pedido "Vários"). Filtro específico = 1 pedido.
- **Fixar** um item (aba Itens) agora **adiciona-o à lista na hora** (via
  `adicionarProdutoSeAusente`); **desfixar** remove (`removerItensPorProduto`).
- Pedidos: **"Este mês economizou R$X"** numa linha só (+ Total à direita).
- **Logo + ícone do app** novos: carrinho minimalista com 2 "V" dentro, azul claro
  degradê em fundo azul escuro. Pipeline: SVG (`scratchpad/icon_*.svg`) → PNG via
  **rsvg-convert** (`apt install librsvg2-bin`) → `assets/icon/icon_full.png` +
  `icon_fg.png` → **flutter_launcher_icons** (dev dep + config no pubspec) gera os
  mipmaps/adaptive. Logo interno = `Image.asset(icon_full.png)`.

### 2026-07-26 (cont.) — Pedidos: excluir, "Sem mercado", filtro ano/mês + ícone maior
- Pedidos (detalhe): **"Excluir pedido"** (apaga sem devolver itens) acima de "Desfazer".
- Pedido sem mercado (itens sem preço) agora diz **"Sem mercado"** (era "Vários mercados").
- **Filtro de ano (dropdown no AppBar) + mês (chips)** na aba Pedidos. Resumo e lista
  respeitam ano+mês+mercado — **somas corretas** por período.
- Ícone/logo: carrinho **maior** e os 2 "V" **saindo pra cima** do carrinho (SVG scale
  1.26/1.12 + V-paths mais altos).

### 2026-07-27/28 — Pacote Play Store + conta enviada + HANDOFF
- **Pacote de lançamento pronto:** AAB (release `playstore-pacote-1`), feature graphic
  1024×500 + ícone 512 (`store/`), política em GitHub Pages (repo público
  `viniciostristao1/lista-privacidade` → https://viniciostristao1.github.io/lista-privacidade/),
  textos + Data Safety (`LANCAMENTO.md`), screenshots (`store/screenshots/`, usar 01-03).
  AAB gerado no CI (`flutter build appbundle --release`).
- **Conta de dev Google Play:** criada + paga (US$25) + documentos enviados → **aguardando
  verificação do Google**.
- **Decisões:** lançar em **PT**; **Inglês (i18n) depois**, como atualização. Grátis, sem anúncios.
- **Handoff completo** no `INICIO.md` (§ ⭐ ESTADO ATUAL) — é a fonte de verdade pós-/clear.
  Também há a memória `project_lista_app.md`. (Não pus no `MEMORY.md` global porque o índice
  do trading já está acima do limite de tamanho — problema pré-existente do trading, à parte.)

### 2026-07-28 — Fix: preços órfãos de mercado excluído (aba Itens)
- **Sintoma:** ao excluir um mercado, os preços dele continuavam aparecendo nos itens,
  só que sem nome (pílula com "—").
- **Causa:** a limpeza (`removerMercadoDeTodos`, do commit `c368c83`) só age **no momento
  da exclusão**. Preços criados antes desse fix (ou exclusão que não completou) ficam
  como órfãos no banco e ninguém os remove depois.
- **Fix (auto-corretivo, 2 camadas):**
  1. `ProdutosRepository.limparPrecosOrfaos(mercadosValidos)` — varre os produtos e
     apaga preços de mercado inexistente + zera `ultimoMercadoId/ultimoPreco` órfão.
     **Guarda:** no-op se `mercadosValidos` vier vazio (evita apagar tudo num loading).
     Disparado 1×/conjunto de mercados ao abrir a aba Itens (`_talvezLimparOrfaos`).
  2. Card da aba Itens filtra `precosOrdenados` pelos mercados existentes → o "—" some
     na hora (e `economia`/`última atualização` recomputam só com mercados válidos).
- **Lição:** limpeza-no-evento não conserta dados legados; para invariantes de dados
  ("nenhum preço aponta pra mercado inexistente"), vale um **backstop idempotente** que
  reconcilia no load, além do gancho na ação.
- **Release:** `v0.13.0-teste16` (título "teste 0.15"), commit `05b09b6`. O release
  passou a carregar **APK arm64 + AAB do mesmo commit** → virou o "pacote canônico".
  Qual AAB subir na Play Store: `LANCAMENTO.md § Build canônico` (= release mais recente).

### 2026-07-29 — Fila de planos futuros (`IDEIAS.md`)
- Criado **`IDEIAS.md`** (planos pós-lançamento, datados e com status), referenciado no
  `INICIO.md`. Semeado com: **mercado dedicado a um item** (Q1+Q2, `[EM DISCUSSÃO]` — vamos
  travar o formato depois), **alternativas de login** (Q3 — hoje Google-only, "esqueci a
  senha" é não-problema por design), e diversos (i18n, monetização, molduras, rede social).

### 2026-07-29 — Changelog do usuário (`ATUALIZACOES.md`)
- Criado **`ATUALIZACOES.md`** = uma linha + data por versão ("o que mudou / o que
  re-testar"), backfill dos releases recentes. **Fluxo travado no `INICIO.md`:** toda
  melhoria visível/release novo entra 1 linha ali (topo = recente). Três arquivos, papéis
  distintos: `APRENDIZADOS` (técnico) · `ATUALIZACOES` (changelog usuário) · `IDEIAS` (futuro).

### 2026-07-30 — Desenho fechado: "mercado dedicado a um item"
- Fechado o design das perguntas 1+2 (ver `IDEIAS.md § 1`, agora `[FUTURO]` desenho FECHADO).
  **3 tipos:** comparável (padrão) · num mercado só (carne, sai ao finalizar) · recorrente
  num mercado (pão, fica). Comparador = padrão; preço só no modo comparar; recorrente sempre
  tem mercado. UX = botão "📌 Comprar sempre num mercado só" (qual mercado + ☐ recorrente),
  some a grade de preço. **Ainda NÃO implementado** — mexe na aba Itens (novos screenshots + AAB).

### 2026-07-30 — Implementado: "mercado dedicado a um item" (versão A)
- Feature do `IDEIAS.md § 1` implementada → **release A = `v0.14.0-teste17`** (commit `f7e4206`).
  Modelo `Produto` ganhou `mercadoFixo`; getters de preço retornam **vazio** quando dedicado
  (não-destrutivo — preços ficam no banco e voltam ao "voltar a comparar"). Editor de Itens:
  botão "Comprar sempre num mercado só" (chips + recorrente), pino do appbar removido. Listas
  usam **mercado efetivo** = `mercadoFixo ?? mais barato` (filtro/finalizar/exportar/cor).
  `removerMercadoDeTodos`/`limparPrecosOrfaos` também limpam `mercadoFixo`/`fixado` órfãos.
  Bug pego na revisão: não apagar produto **dedicado** ao remover da lista (é entrada deliberada).
- **B (`v0.13.0-teste16`) é o fallback testado; A está A VERIFICAR pelo usuário** (ver `LANCAMENTO.md`).
- **Polido o botão** "Comprar sempre num mercado só" (full-width; a frase + ícone estouravam o
  contorno) → **rebuild A = `v0.14.1-teste18`** (commit `89131a5`). Ideia do usuário de
  **lembretes programáveis** (notificação local por dia da semana) salva no `IDEIAS.md § 3`.

### 2026-08-09 (cont.) — Editor mercados fix + ordenar categorias (`v0.32.0-teste37`)
- **Bug "Salvar sumiu" (5+ mercados):** o sheet era `Column(min)` sem scroll → estourava e o botão
  saía da tela. Fix: `ConstrainedBox(maxHeight 0.85h)` + `Flexible(SingleChildScrollView)` p/ os slots +
  **Salvar fixo** embaixo; `padding.bottom = viewInsets` (teclado). Campo novo: `autofocus`(via `_Slot.novo`)
  + `textCapitalization`. Nome do mercado capitaliza no repo.
- **Ordenar categorias:** `Categoria.utilidades` add. `categoriaOrdemProvider` (prefs, Notifier<List<Categoria>>;
  novas categorias entram no fim). Folha `ReorderableListView.builder` (`onReorderItem`, drag handle). Aplicado
  em `_itensAgrupados` (itera a ordem custom, não `Categoria.values`). Botão na aba Itens (linha de tools rolável).

### 2026-08-09 (cont.) — ⭐ principal fixo ao lado de "Todos" (`v0.31.0-teste36`)
- Repropósito do ⭐ (perdeu o roteamento): o mercado com `preferencia` vira chip em destaque
  (com estrela) logo após "Todos". Ordem da barra: Todos > ⭐principal > Sem mercado > demais
  (`mercados.where(preferencia)` / `where(!preferencia)`). `_chipFiltro` ganhou `estrela`.

### 2026-08-09 (cont.) — Lupa + 8 mercados + Sem mercado (`v0.30.0-teste35`)
- **#1 Ícone**: logo v3 (carrinho + lupa com "$") extraído p/ vetor/PNG (`design/logo_v3_lupa.png`).
- **#2** `_maxMercados` 3→8; `mercadoCores` = 8 hues distintos (sem o âmbar do acento).
- **#3** cadastrar item novo já num mercado: `_cadastrarEmMercado(nome, id)` (cria `mercadoFixo`);
  chips no `_resultadosBusca` (⭐ primeiro via `_mercadosOrdenados`).
- **#4** chip **"Sem mercado"** (`_filtroSemMercado`, itens com efetivo null). **Mudança:**
  `_mercadoEfetivo` deixou de rotear soltos pro ⭐ preferido → soltos caem em "Sem mercado". ⭐
  virou "mercado principal" (só ordena o cadastrar-em-mercado). `_preferidoId` removido (órfão).

### 2026-08-09 — Enter na busca adiciona + texto mercados (`v0.29.0-teste34`)
- Campo de busca: `textInputAction.done` + `onSubmitted` → `_submeterBusca` (exato do catálogo ou
  cadastra+adiciona). `_campoBusca` passou a receber `produtos`+`idsNaLista`.
- Editor de mercados: "Até 3 favoritos" → "Até 3 mercados" (favorito confundia com a ⭐ preferência única).

### 2026-08-08 — Logo do usuário + mercado preferência + refinos (`v0.28.0-teste32`)
- **#1 Ícone** do logo enviado (`design/logo_v2.png`). Sem imagemagick/PIL no sistema → **venv
  isolado** no scratchpad c/ Pillow; script `extrai_icone.py`: flood-fill dos cantos pretos→âmbar,
  extração do carrinho por **alfa-luminância** (anti-alias), bbox só dos pixels opacos, fg centrado
  a 66%, bg degradê. Ficou fiel e nítido.
- **#2 Mercado preferência**: `Mercado.preferencia` (bool) + repo criar/atualizar; editor de mercados
  ganhou ⭐ **exclusivo** (`_togglePreferencia`). `_mercadoEfetivo` virou **método** lendo `_preferidoId`
  (setado no build): `mercadoFixo ?? maisBarato ?? preferido`. Itens sem preço caem no preferido.
- **#3** caixa Economia padding vert 14→9. **#4** desfazer: **Timer manual 3s** + `ctrl.close()`
  (timer interno do SnackBar não dispara c/ animações do sistema off — bug Flutter). **#5** marca
  capitaliza no repo + textCapitalization.
- **⚠️ COTA DE ARTEFATO DO ACTIONS ESTOUROU (2026-08-08):** ~54 builds = 2 GB > limite grátis 500 MB;
  upload de artefato passou a falhar (`Artifact storage quota has been hit`), e **apagar não libera na
  hora** (GitHub recalcula a cada 6-12h). **Fix:** o `build-apk.yml` agora builda só **arm64** + AAB e
  publica no **release rolling `ci-latest`** (`softprops/action-gh-release`, `permissions: contents:write`)
  — **assets de release NÃO contam na cota**. **Novo fluxo p/ cortar release:** `gh release download
  ci-latest` → `gh release create vX ...`. NÃO voltar a `upload-artifact`.
- **⚠️ "Pacote inválido" no v0.28.0 (2026-08-08):** ao migrar o build troquei `--split-per-abi` por
  `--target-platform android-arm64` p/ economizar. Isso **zerou o offset de versionCode**: o
  `--split-per-abi` soma **+2000** no arm64 (arm64 = 2·1000 + base), mas o single-arch usa o **base**
  → o APK novo tinha versionCode MENOR que o instalado (todos os releases v0.13→v0.27 eram split=2001)
  → **downgrade**, Android recusa ("pacote parece inválido"). Assinatura estava OK (v2). **Regra:
  MANTER `--split-per-abi` e publicar `app-arm64-v8a-release.apk`** (versionCode estável 2001).
  Diagnóstico: `grep -a "APK Sig Block 42"` (assinatura v2) e conferir versionCode.

### 2026-08-01 (cont.) — Finalizar-só-marcados + ordem + refinos (`v0.27.0-teste31`)
- **#6 Finalizar** processa só `comprado==true` (não-fixado); não marcados ficam. `removiveis`
  ganhou `it.comprado &&`. Botão de finalizar só aparece com ≥1 marcado.
- **#5 Ordem**: itens da lista eram doc-id do Firestore (aleatório) → agora **alfabético dentro
  da categoria** (`..sort` por nome). `watchItens` segue sem orderBy no repo.
- **#1/#2**: item dedicado **não reserva** o espaço de preço (const width 56→0; nome ganha o
  espaço). Comentário no código diz como reverter (44=1-díg, 56=2-díg).
- **#3** título "Itens | Comparador". **#7** categoria→item bottom 1→0. **#8** desfazer: tirado
  `SnackBarBehavior.floating` (auto-fechava mal em alguns casos), mantido 3s.

### 2026-08-01 (cont.) — Contagem/desfazer/alerta + categorias (`v0.26.0-teste30`)
- **Chips** de mercado mostram contagem discreta `(n)` (Todos=total; mercado=itens por mercado efetivo).
- **Desfazer** no swipe: `_removerComDesfazer` guarda os campos do item + se o produto era lembrete
  solto (apaga); SnackBar 3s com ação que recria (produto, se preciso) e re-adiciona o item.
- **Categorias** aba Listas: top subseq 9→4, 1ª 2→1 (bottom 1; item vert 0). **Números reportados ao
  usuário** pra ele pedir ajuste fino.
- **Editor**: caixa de **alerta** (borda/tint `danger`) na seleção de mercado enquanto nenhum escolhido;
  `_salvar` bloqueia se `_abrirMercadoFixo && mercadoFixo==null` (evita salvar "num mercado só" vazio).

### 2026-08-01 (cont.) — Fontes recalibradas + ícone maior (`v0.24.0-teste28`)
- Fontes: fatores **0.93/1.035/1.22** (≈13,5/15/17,7 sobre o texto-base 14,5); **padrão=1.035**
  (Normal ~15). Lista ainda mais enxuta (item vert 1→0; stepper 24→22; editar 24→22; checkbox mantido
  20 p/ não sacrificar o toque). Ícone maior (full 1.24→1.31; fg 1.08→1.14).

### 2026-08-01 (cont.) — Aba Itens compacta + ícone maior (`v0.23.0-teste27`)
- **Aba Itens**: pílula de preço de 2 linhas → **1 linha** (`● Mercado  R$ x,xx`); **mais barato
  preenchido âmbar** (era só borda verde), badge "MENOR" removido. Card com padding/espaços menores.
- **Imagens** que o usuário subiu movidas p/ `design/` (`icone_carrinho_ref.png` = flat 2D fonte do
  ícone; `_3d.png` = mockup). **`git mv`** (estavam na raiz).
- Ícone maior (full 1.15→1.24, fg 1.0→1.08). Listas ainda mais enxuta (item vert 2→1; checkbox 22→20;
  stepper 26→24; editar minH 28→24).

### 2026-08-01 (cont.) — Colunas alinhadas + ícone maior (`v0.22.0-teste26`)
- **Alinhamento da lista**: item dedicado (sem preço) reservava 0 → colapsava a linha. Fix: no
  lugar do preço, `SizedBox(width:56)` (≈"R$ x,xx"); bolinha do mercado virou slot fixo 9×9. Preços
  seguem largura natural (usuário aceita variação por casas decimais). Editar/qtd/preço/bolinha alinham.
- **Ícone** um tico maior (full scale 1.02→1.15, fg 0.9→1.0). Itens ainda mais colados (vert 4→2).

### 2026-08-01 — Ícone do usuário + fonte ajustável + refinos (`v0.21.0-teste25`)
- **Ícone**: usuário subiu o desenho que quer (2 PNGs na raiz do repo: `1785543967712.png` =
  flat, `1785544256190.png` = 3D). **Recriado em vetor** (SVG no scratchpad) fiel ao desenho:
  cesta gridada (4v+1h), **chassi em "S"** + barra, **rodas em anel** (stroke), alça curva. Fundo
  **âmbar degradê** (`#EEB24E→#DB9528`); adaptativo passou a usar **imagem** de fundo
  (`adaptive_icon_background: assets/icon/icon_bg.png`) pra manter o degradê.
- **#4 fonte ajustável**: `shared_preferences` add; `services/prefs.dart` (NotifierProvider<double>,
  Riverpod 3) persiste 0.9/1.0/1.2; `main.dart` aplica com `MediaQuery.withClampedTextScaling`
  (min=max=escala) → app inteiro. Engrenagem na aba Listas (antes do copiar) abre sheet.
- **#1** Finalizar some com teclado (`viewInsets.bottom==0`). **#5** pino recorrente movido p/ depois
  da descrição. **#3** item vertical 6→4.

### 2026-07-31 (cont.) — Maiúscula + lista + rodas do ícone (`v0.20.0-teste24`)
- **Maiúscula inicial** no nome: `capitalizar()` em `format.dart` aplicado no repo (`nome`, mantendo
  `nomeLower`); + `textCapitalization.sentences` na busca e no campo Nome. Cobre entrada por **voz**
  (o forçar-no-código é o confiável; textCapitalization só ajuda o teclado). A lista exibe `p.nome`
  então basta capitalizar no produto.
- Lista **mais enxuta**: item vertical 8→6; categoria top subseq 14→9, bottom 2→1.
- **Ícone**: arco em C reprovado. Rodas refeitas com **eixo/frame abaixo da cesta** (trapézio
  convergente `M430 672 L470 726 H650 L708 672` + 2 rodas abaixo) — estilo carrinho da busca.

### 2026-07-31 (cont.) — Lista enxuta + pé do ícone em C (`v0.19.0-teste23`)
- Espaçamento da lista apertado: item `vertical 13→8`; categoria→1º item `bottom 6→2` (top de
  seção subsequente 6→14 pra separar seções). Ícone: pé vira **arco em C** (`Q`) com as rodas nas pontas.

### 2026-07-31 (cont.) — Flat nos itens da lista + ícone refinado (`v0.18.0-teste22`)
- Feedback: o Flat da `teste21` deixou os **itens da lista** ainda com caixinha (surface). Fix:
  `_itemRow` perde o card → `padding` no fundo do app + `Border(bottom)` fino (`lineStrong`); o
  background do Dismissible virou faixa lisa. **Caixinhas do cadastro (aba Itens) mantidas de propósito**
  (usuário gosta). Lição: "flat" no exemplo = itens sobre o bg com divisória, não card borderless.
- **Ícone** refinado: + **grade horizontal** (grade 3×2), **alça mais vertical**, e o **pé/base**
  (barra onde os carrinhos encaixam) com as rodas embaixo.

### 2026-07-31 (cont.) — Estilo Flat aplicado + ícone c/ grades (`v0.17.0-teste21`)
- Usuário escolheu o estilo **Flat** (da página-preview). Implementado de forma central e barata:
  **`AppColors.line` → transparente** (some o contorno de TODOS os cards de uma vez; separação =
  contraste bg/surface); `lineStrong` (8%) só p/ arestas estruturais (stepper/inputs). **Botões
  preenchidos** (Finalizar + "num mercado só" viram cheios) e **chips selecionados sólidos** (âmbar)
  em Listas/Itens/Pedidos. Lição: com cores centralizadas em `AppColors`, dá pra virar a "cara"
  (flat) mexendo em ~7 pontos, sem tocar nos 21 `Border.all`.
- **Ícone**: carrinho **maior** (scale 1.16 full / 1.0 fg) + **grades verticais** dentro da cesta.
- **Cor (âmbar) e estilo (Flat) travados** → A = `v0.17.0-teste21` é o candidato de lançamento.

### 2026-07-31 (cont.) — Âmbar definido + ícone carrinho + títulos (`v0.16.0-teste20`)
- Usuário escolheu **âmbar** entre A/B/C → virou o acento padrão no `main`; branches `layout-*`
  apagados. **Ícone refeito**: carrinho da busca (Material), **preto sobre âmbar, SEM V** (SVGs no
  scratchpad, não versionados); fundo adaptativo do Android → âmbar (`pubspec adaptive_icon_background`).
- **Símbolo antes do título** em cada aba (checklist/tag/gráfico, cor do acento).
- **Estilo (botões/bordas/cartões) ≠ cor:** usuário quer "cara diferente" com **botões preenchidos**.
  Como estilo mexe em muitos componentes, entreguei uma **página-preview** (Artifact) com a MESMA tela
  em 4 estilos (Atual + A sólido / B cartão / C flat) pra ele escolher a direção → depois implemento
  o escolhido de verdade. **PENDENTE: escolha do estilo → aplicar + rebuildar AAB.**

### 2026-07-31 — Ícone novo + atalhos + 3 layouts (`v0.15.0-teste19`)
- **Ícone redesenhado** (carrinho + 2 "V" saindo da cesta; mais alto/fino, minimalista). SVG-fonte
  **não** existia no repo → recriado do zero em `SVG → rsvg-convert → view → flutter_launcher_icons`;
  os SVGs ficaram no scratchpad (não versionados — se refazer, recriar). Regenerou mipmaps+fg/full+loja+web.
- **#3** atalho de editar item na aba Listas (🏷️ antes da qtd → `mostrarEditorProduto`). **#4** busca
  = 🛒 "Pesquise ou adicione aqui".
- **#2 três layouts** (só acento+contornos, todos escuros): **A verde** (`main`), **B índigo**
  (branch `layout-indigo`), **C âmbar** (branch `layout-ambar`). Build via `gh workflow run
  build-apk.yml --ref <branch>` (workflow_dispatch). **Seletor ao vivo foi descartado**: cores são
  `const` de compilação (AppColors) → runtime exigiria de-const do app todo (arriscado). Por isso 3
  builds; dados na nuvem tornam a troca de APK sem perda. **Pendência: usuário escolhe → fundir o
  app_colors do branch no `main`, apagar branches `layout-*`, rebuildar o AAB de lançamento.**

---

## Aprendizados (gotchas — não repetir)

1. **Login `CONFIGURATION_NOT_FOUND` = Autenticação não provisionada** (não é SHA-1!).
   Ativar de verdade: Authentication → *Get Started* → Google → Ativar + **e-mail de
   suporte** → Salvar. Verificar por API, sem o app:
   `curl -X POST 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=<APIKEY>'`
   → `CONFIGURATION_NOT_FOUND` (ruim) vs `ADMIN_ONLY_OPERATION` (ok, provisionada).
2. **`invalid-cert-hash`** = o app foi assinado com um keystore cujo **SHA-1 não está
   registrado** no Firebase. Registrar SHA-1 (Config do app Android → impressões SHA)
   e assinar com um **keystore fixo** (não o debug efêmero do CI).
3. **Assinatura estável no CI:** keystore em *secret* (base64) + `key.properties`
   reconstruído no workflow. Sem isso, cada build tem assinatura diferente → precisa
   desinstalar pra atualizar. Conferir a assinatura de um APK:
   `apksigner verify --print-certs app.apk`.
4. **Play Protect bloqueia APK de fora da loja** ("app não foi instalado"): desligar o
   Play Protect temporariamente OU tocar em "Instalar mesmo assim".
5. **Enviar arquivo em `.github/workflows/` exige o escopo `workflow`** no token do gh:
   `gh auth refresh -s workflow` (device flow — digita um código no github.com/login/device).
6. **`firebase login --no-localhost` está bugado** ("Unable to verify client"):
   configuramos o Firebase pelo **console manual**, não pela flutterfire CLI.
7. **APK debug é gigante (~149 MB)**; release por arquitetura (`--split-per-abi`) ~19 MB.
   Sempre distribuir o **arm64-v8a** (celulares modernos).
8. **Riverpod 3.x:** ler valor de um provider assíncrono com `.asData?.value`
   (o `valueOrNull` não existe). `Provider`/`StreamProvider` clássicos funcionam.
9. **Login Google:** começamos com `signInWithProvider` (Generic IDP/navegador) pra
   evitar SHA-1/serverClientId, MAS é **frágil** — deu `CONFIGURATION_NOT_FOUND` e depois
   "Failed to generate/retrieve public encryption key for Generic IDP flow".
   **Migramos pro `google_sign_in` 7.x nativo** (Credential Manager):
   `GoogleSignIn.instance.initialize(serverClientId: <Web client ID>)` → `.authenticate()`
   → `GoogleAuthProvider.credential(idToken: account.authentication.idToken)` →
   `signInWithCredential`. Web client ID em **Auth → Google → Config SDK Web**
   (`585404124028-bjf...apps.googleusercontent.com`); exige **SHA-1 registrado** (temos).
   Mais robusto e melhor UX (seletor de conta nativo).

---

## Decisões de produto

- **Preços moram no catálogo (aba Itens)**, por mercado, cada um com **data**.
- **Aba Listas** deve mostrar o **menor preço** + a bolinha do mercado mais barato, com
  o mesmo alerta de desatualizado.
- **Economia:** por item = `2º menor − menor` (com 3 mercados, o 3º é ignorado); item
  com 1 só mercado não entra. **Geral** = soma das economias + **percentual**.
- **Alerta vermelho** quando o preço tem mais de **30 dias**.
- Campos opcionais do produto: **marca, tamanho, unidade** (texto livre).
- **Lista rápida (25/07):** Listas = 1 lista só; adiciona por busca no catálogo, sem
  digitar preço; destaque = economia + %; "estimado" como secundário.
- Finalizar = **arquiva um pedido** (data/mercado/total/economia/itens) e remove os
  itens visíveis não-fixados. Dá pra **desfazer** o pedido (itens voltam à lista).
- Editar mercados vive na aba **Itens**.
- **Categorias:** lista fixa ampliada (13), não editáveis (decisão 25/07).
- **Escala/custo:** a VPS só compila; o backend é o Firebase, que escala a milhões.
  Grátis (Spark) cobre ~1.000–1.500 usuários ativos/mês; no Blaze ~US$0,001/usuário/mês
  (uso leve). Gargalo = **custo (baixo)**, não capacidade. Ligar alerta de orçamento.
- Aba **Pedidos** CONSTRUÍDA (26/07): histórico + resumo do mês + desfazer pedido.
- Próximos possíveis: ícone do launcher (logo), polimento, e preparar o AAB/Play Store.

---

## Publicar na Play Store (checklist, quando for a hora)
1. Conta de desenvolvedor Google Play — **US$25 (uma vez)**.
2. Trocar o build de APK para **AAB** assinado (a keystore de upload já existe).
3. Ficha: nome, descrição (curta+longa), **ícone 512×512**, gráfico 1024×500, prints,
   categoria, e-mail de contato.
4. **Política de privacidade** (URL) — hospedar de graça (ex.: GitHub Pages).
5. Formulário de **segurança de dados** (coleta: e-mail do login + itens do usuário) +
   classificação de conteúdo + público-alvo.
6. ⚠️ **Conta pessoal nova:** exige **teste fechado com ~12 testadores por 14 dias**
   antes de liberar produção. Conta empresa pula, mas exige CNPJ/verificação.
7. Revisão do Google: horas a dias. Update depois = subir AAB novo.
8. Monetização (depois): AdMob ou premium.

### Decisões de lançamento (definidas)
- **Título na loja:** `Lista e comparador de mercado` (29/30 caracteres).
- **Nome no ícone (label):** `Lista` (AndroidManifest `android:label`).
- **Package (permanente):** `com.vinyapps.lista_app`.
- **Monetização:** a decidir (recomendação: grátis, sem anúncios no lançamento).
- Interação: o usuário prefere conversar (evitar o tool de perguntas com caixinhas).
