# Lista App — INÍCIO (ler primeiro em toda tarefa)

App **Flutter** de lista de compras de supermercado. Simples, rápido, design escuro
moderno (referência visual: "ADI Predict Street" — cards arredondados, tipografia clean).
Meta: publicar na **Play Store**.

> ⚠️ Projeto isolado. Vive **só** em `/root/lista_app/`.
> NUNCA tocar em `/root/trading/`, `/root/trading_acoes/`, `/root/trading_opcoes/`.

> 📓 **Fluxo fixo:** ao fim de cada bloco significativo, atualizar
> [`APRENDIZADOS.md`](APRENDIZADOS.md) (diário técnico + lições) e dar **commit/push**.
> Ler `APRENDIZADOS.md` antes de mexer em login/build/assinatura (gotchas conhecidos).
> **⚠️ Toda melhoria visível ao usuário / release novo → UMA LINHA (resumo + data) em
> [`ATUALIZACOES.md`](ATUALIZACOES.md)** — é o "o que mudou / o que re-testar" pro usuário
> (topo = mais recente). Planos futuros → [`IDEIAS.md`](IDEIAS.md). Os três arquivos têm
> papéis distintos: técnico (`APRENDIZADOS`) · changelog do usuário (`ATUALIZACOES`) · futuro (`IDEIAS`).

## ⭐ ESTADO ATUAL (2026-07-28) — ler primeiro pós-/clear

**O app está COMPLETO e funcional** (em Português). Fase atual = **LANÇAMENTO na Play Store**.

**O que existe e funciona:**
- 3 abas completas: **Listas** (compra atual, busca no catálogo, economia, quantidade,
  fixar, filtro/exportar), **Itens** (catálogo + comparador de preço por mercado +
  frescor/data + calculadora), **Pedidos** (histórico separado por mercado + filtro
  ano/mês + resumo do mês + desfazer/excluir pedido).
- **Login Google NATIVO** (google_sign_in) funcionando. Firebase `lista-app-e08e2`.
- **Ícone/logo:** carrinho com 2 "V" (azul), gerado via SVG→rsvg→flutter_launcher_icons.
- Distribuição de teste: **releases no GitHub** (APK arm64). **Duas versões (2026-07-30):**
  **B = `v0.13.0-teste16`** (commit `05b09b6`) — **testada pelo usuário ✅**, fallback seguro;
  **A = `v0.30.0-teste35`** (commit `429e949`) — feature "mercado dedicado" + **âmbar** + **ícone
  do desenho do usuário** (cesta gridada/chassi-S/rodas-anel, âmbar degradê, maior) + símbolos nos
  títulos + atalhos + **estilo Flat** (Listas enxuta/alinhada; **Itens compacta**: pílula 1-linha
  `● Mercado R$x`, mais-barato preenchido) + nome com **maiúscula** + **⚙️ ajuste de fonte**
  (`services/prefs.dart`; fatores 0.93/1.035/1.22 = ~13,5/15/17,7; padrão=1.035). Imagens-ref em
  `design/`. **Cor e estilo travados** → falta a verificação do usuário. Detalhe em `LANCAMENTO.md`.
  ⚠️ NÃO subir o `playstore-pacote-1` antigo.

**Lançamento — onde paramos:**
- Conta de desenvolvedor Google Play **criada + paga (US$25) + documentos enviados**
  → **AGUARDANDO verificação de identidade do Google** (horas a dias).
- **Pacote pronto** (tudo em `LANCAMENTO.md` + `store/`): AAB, feature graphic 1024×500,
  ícone 512, 3-4 screenshots (`store/screenshots/`), política no ar
  (https://viniciostristao1.github.io/lista-privacidade/), textos + Data Safety.
- **Decisão:** lançar em **PT agora**; **Inglês (i18n) depois** como atualização.
- **Monetização:** grátis, sem anúncios (decisão do usuário).

**O que falta (para o próximo passo):**
1. Google aprovar a verificação → então **Marco ②**: criar o app no Play Console,
   preencher a ficha (colar de `LANCAMENTO.md`), subir AAB + gráficos + screenshots,
   Data Safety, classificação, link da política.
2. **Teste fechado: 20 testadores / 14 dias.** 3. Produção.
4. **Pendência prometida:** dar ao usuário uma **cópia da keystore** (upload key) pra
   backup pessoal (está em `KEYSTORE_BASE64`/`KEYSTORE_PASSWORD` nos secrets do repo).

**Ideias & planos futuros → [`IDEIAS.md`](IDEIAS.md)** (fila pós-lançamento, datada e com
status). Hoje lá: **mercado dedicado a um item** (Q1+Q2, `[EM DISCUSSÃO]` — formato a
travar), **alternativas de login/recuperação** (Q3: hoje Google-only, sem senha por
design), i18n (inglês), monetização, molduras nos screenshots, rede social + preços por bairro.

**Dados do usuário ficam na NUVEM (Firebase), ligados ao login** — trocar do APK do
GitHub para a versão da Play Store NÃO perde nada (loga e tudo volta).

## O que o app faz (MVP)
Três abas:
- **📋 Listas** — cria listas, adiciona itens (autocomplete do histórico), marca como
  comprado, total ao vivo. No topo: **legenda dos mercados** (cor→nome); tocar abre o
  editor **"Meus mercados"** (nome + cor, até 3 favoritos).
- **🏷️ Itens** — catálogo pessoal: cada produto com o **preço em cada mercado**
  (comparador entre mercados) + evolução do preço no tempo.
- **📊 Pedidos** — histórico de compras finalizadas + **resumo do mês** (gasto,
  top itens, evolução de preço).

## Princípios (não violar)
1. **Sem catálogo pronto** — o catálogo nasce vazio e cresce com o que o usuário digita.
2. **Sem dependência externa** — nada de scraping/API de mercado. 100% dados do usuário.
3. **Cadastro leve** — nome obrigatório; preço/mercado/categoria opcionais.
4. **Privacidade** — cada usuário vê só os seus dados.
5. **Simples** — mais rápido que abrir o WhatsApp e digitar.

## Técnico
- Flutter (Android primeiro, iOS depois)
- Firebase: Firestore (dados + sync offline) + Auth (login Google)
- Estado: **Riverpod**
- Arquitetura: feature-based (`lib/features/<feature>/`)
- **Build de release: na nuvem (GitHub Actions)** — a VPS é fraca p/ compilar Android.

## Firestore (modelo)
Tudo aninhado sob o usuário (regra de segurança: `users/{uid}` só pro dono):
- `users/{uid}` — perfil
- `users/{uid}/mercados/{id}` — favoritos (máx 3): `nome, cor`
- `users/{uid}/produtos/{id}` — catálogo pessoal (vira sugestão): `nome, nomeLower,
  categoria, ultimoPreco, ultimoMercadoId, vezesComprado`
- `users/{uid}/listas/{id}` — `nome, status(ativa|finalizada), createdAt,
  finalizadaAt, mercadoPredominanteId, totalGasto, qtdItens`
- `users/{uid}/listas/{id}/itens/{id}` — `produtoId?, nome, categoria, quantidade,
  preco?, mercadoId?, comprado`
- `users/{uid}/precos/{id}` — observações p/ gráfico/comparador: `produtoId, nome,
  preco, mercadoId, data, listaId`

## Fases
- **Fase 1 (atual):** lista pessoal + preço manual + 3 mercados + total ao vivo +
  login Google + sync + design escuro.
- **Fase 2:** histórico, comparador, resumo mensal, templates.
- **Fase 3:** compartilhar lista (família).
- **Fase 4:** preços anônimos por bairro.

## Como VER/testar (leigo em apps)
1. **Maquete HTML** — visual clicável (só design, não é o app).
2. **Flutter web** — o app real como página, p/ iterar telas.
3. **APK no Android** — construído na nuvem, instalado no celular. É o que vai pra loja.

## Ambiente
VPS: 1 vCPU, 3.8 GB RAM (sem swap), ~34 GB livres. OK p/ codar; build de release
sai na nuvem. Flutter **3.44.7** / Dart **3.12.2** em `/root/flutter`.

## Estado do Firebase (conectado em 2026-07-24)
- Projeto: **lista-app-e08e2** (dono: viniciostristao@gmail.com).
- App Android registrado: pacote **com.vinyapps.lista_app**.
- **Auth Google** ativado. **Firestore** criado em `southamerica-east1` (modo produção).
- Config LOCAL, fora do Git: `app/android/app/google-services.json` +
  `app/lib/firebase_options.dart` (**só Android** por ora; Web quando formos ao preview).
- Plugin `com.google.gms.google-services` no Gradle; `minSdk >= 23`.
- ⚠️ `firebase login --no-localhost` está **bugado** ("Unable to verify client") →
  configuramos via **console manual**, não via flutterfire CLI. Deploy de regras =
  colar `firestore.rules` na aba **Regras** do console. Se precisar de CLI no futuro:
  usar service account.

### Login Google — FUNCIONANDO (resolvido 2026-07-25)
Método: `FirebaseAuth.signInWithProvider(GoogleAuthProvider())` (fluxo browser, sem
google_sign_in nativo). 3 causas que travaram o login (todas resolvidas):
1. **Auth não estava provisionada** — apesar do "liguei o Google" inicial, o provedor
   não salvou. Sintoma: `CONFIGURATION_NOT_FOUND`. Fix: Authentication → Get Started →
   Google → Ativar + **e-mail de suporte** → Salvar. **Verificar daqui** (sem app):
   `curl -X POST 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=<APIKEY>'`
   → `CONFIGURATION_NOT_FOUND` = não provisionada; `ADMIN_ONLY_OPERATION` = OK.
2. **cert-hash** (`invalid-cert-hash`) — o app precisa ser assinado com um keystore cujo
   **SHA-1 esteja registrado** no Firebase (Configs do app Android → impressões SHA).
   SHA-1 da chave de upload: `FB:02:95:85:16:45:D3:05:16:BA:58:08:38:EB:FD:2F:9E:23:C0:F0`.
   Conferir assinatura de um APK: `apksigner verify --print-certs <apk>`.
3. **Assinatura instável do CI** — resolvido com keystore fixo (secrets), acima.
Release atual testável: **v0.1.2-teste3**. `google-services.json` ainda com oauth_client
vazio (não importa p/ signInWithProvider; atualizar só se migrar p/ google_sign_in nativo).

## Estado do build / CI (APK funcionando desde 2026-07-24)
- **Fase 1 = FUNCIONAL e testável.** Aba Listas completa (criar/abrir listas,
  add item c/ autocomplete, marcar, total ao vivo, editor de mercados, finalizar).
  Abas Itens/Pedidos = placeholders (são a Fase 2).
- **CI:** `.github/workflows/build-apk.yml` gera `app-debug.apk` na nuvem. Config do
  Firebase injetada via **secrets** `GOOGLE_SERVICES_JSON` + `FIREBASE_OPTIONS_DART`
  (base64), porque os arquivos são gitignored.
- ⚠️ Push de workflow exigiu escopo **`workflow`** no token gh (adicionado via
  `gh auth refresh -s workflow`, device flow).
- **Cortar um APK de teste (fluxo desde 2026-08-08):** push em `app/**` → o CI builda arm64 + AAB
  e publica no **release rolling `ci-latest`** (artefato do Actions foi abandonado: a cota estourou;
  ver `APRENDIZADOS`). Baixar: `gh release download ci-latest` → `gh release create <tag>
  lista-app-vX-arm64.apk lista-app-vX.aab`.
- **Login em runtime:** `signInWithProvider` (browser). Ainda **sem SHA-1** — trocar
  pelo google_sign_in nativo + SHA-1 ao preparar o release assinado pro Play Store.
- APK debug é grande (~149 MB, todas as ABIs). Release final será bem menor.
- Só Android no Firebase → preview web exige registrar um app Web depois.
