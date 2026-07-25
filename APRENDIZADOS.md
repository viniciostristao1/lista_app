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
9. **google_sign_in 7.x** tem API nova e exige SHA-1/serverClientId. Optamos por
   `FirebaseAuth.signInWithProvider(GoogleAuthProvider())` (fluxo pelo navegador) —
   mais simples e funciona. Migrar pro nativo só se quiser o seletor de conta do Android.

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
- Finalizar = remove os itens visíveis (por filtro de mercado); Todos = tudo. Ainda
  **não** arquiva em histórico (isso entra quando repensarmos Pedidos).
- Editar mercados vive na aba **Itens**.
- Pendências abertas: **editar categorias** (tornar editáveis) e aba **Pedidos**
  (repensar — será mais complexa).
