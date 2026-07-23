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
sai na nuvem. Flutter/Android SDK sendo instalados.
