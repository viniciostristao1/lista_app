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
