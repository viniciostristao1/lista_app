# Lista App — INÍCIO (ler primeiro em toda tarefa)

App **Flutter** de lista de compras de supermercado. Simples, rápido, design escuro
moderno (referência visual: "ADI Predict Street" — cards arredondados, tipografia clean).
Meta: publicar na **Play Store**.

> ⚠️ Projeto isolado. Vive **só** em `/root/lista_app/`.
> NUNCA tocar em `/root/trading/`, `/root/trading_acoes/`, `/root/trading_opcoes/`.

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

## Estado do build / CI (APK funcionando desde 2026-07-24)
- **Fase 1 = FUNCIONAL e testável.** Aba Listas completa (criar/abrir listas,
  add item c/ autocomplete, marcar, total ao vivo, editor de mercados, finalizar).
  Abas Itens/Pedidos = placeholders (são a Fase 2).
- **CI:** `.github/workflows/build-apk.yml` gera `app-debug.apk` na nuvem. Config do
  Firebase injetada via **secrets** `GOOGLE_SERVICES_JSON` + `FIREBASE_OPTIONS_DART`
  (base64), porque os arquivos são gitignored.
- ⚠️ Push de workflow exigiu escopo **`workflow`** no token gh (adicionado via
  `gh auth refresh -s workflow`, device flow).
- **Cortar um APK de teste:** build roda no push em `app/**` → baixar artefato →
  `gh release create <tag> lista-app.apk`. Release atual: `v0.1.0-teste1`.
- **Login em runtime:** `signInWithProvider` (browser). Ainda **sem SHA-1** — trocar
  pelo google_sign_in nativo + SHA-1 ao preparar o release assinado pro Play Store.
- APK debug é grande (~149 MB, todas as ABIs). Release final será bem menor.
- Só Android no Firebase → preview web exige registrar um app Web depois.
