# Ideias & Planos futuros — Lista App

Lugar único pra registrar o que **ainda não vamos fazer agora**, mas não queremos
esquecer. Evita re-discutir do zero e serve de fila pós-lançamento.

## Como usar
- Entrada curta, **datada**, com **status**:
  `[EM DISCUSSÃO]` (formato ainda aberto) · `[FUTURO]` (aceito, sem data) ·
  `[ADIADO]` (decidido não fazer agora, com o porquê) · `[FEITO]` (vira linha no diário do `APRENDIZADOS.md` e sai daqui).
- Ao **decidir** implementar algo, mover o detalhe pro fluxo normal (código +
  `APRENDIZADOS.md`) e marcar `[FEITO]` aqui.
- Detalhe do "porquê" mora aqui; o `INICIO.md` só aponta pra este arquivo.

---

## 1. Mercado dedicado a um item (perguntas 1 + 2)  — `[EM TESTE]` · **implementado 2026-07-30 (release A `v0.14.0-teste17`)**
*(implementado; move pra `[FEITO]` quando o usuário validar. O que foi feito: `APRENDIZADOS.md` 2026-07-30.)*

**Dor:** hoje todo item da lista é comparável (preço por mercado + economia). Faltam
dois casos que a pessoa quer, **sem preço**:
- **Num mercado só** (ex.: carne — não compra todo dia, mas prefere o açougue de confiança).
- **Recorrente** (ex.: pão — come todo dia; deve **ficar sempre na lista**).

**Modelo final — 3 tipos:**

| Tipo | Mercado | Preço | Sai ao finalizar? | Exemplo |
|---|---|---|---|---|
| **Comparável** (padrão) | nenhum | sim | sim | leite (compara) |
| **Num mercado só** | X | não | **sim** | carne (açougue) |
| **Recorrente num mercado** | X | não | **não (fica)** | pão (padaria) |

**Regras:**
- **Comparador é o padrão** — item nasce comparável; **não** há escolha de "modo".
- **Preço só existe no modo comparar** (mercado definido ⇒ nada a comparar ⇒ preço some).
- **Recorrente SEMPRE tem mercado** (não existe "recorrente onde der").
- Item com mercado aparece em **Todos + o chip daquele mercado** ("Todos" = superconjunto).
- "Num mercado só" e "recorrente" são **dois controles separados** (o recorrente é o
  antigo `fixado` = "não sai ao finalizar", agora exigindo mercado).

**UX — editor da aba Itens:** comparador é o normal (grade de preço por mercado). Uma
**ação** opcional — botão **"📌 Comprar sempre num mercado só"** — abre:
- **Em qual mercado?** [A] [B] [C]
- **☐ Compra recorrente** (não sai ao finalizar) → distingue **pão** (marcado) de **carne** (não).

Ao ativar: **a grade de preço some** (anotar em Observações se quiser). **"Voltar a
comparar"** desfaz. Rótulo com texto (não ícone solto) — o app tem usuário leigo.

**UX — aba Listas:** adicionar com o filtro de um mercado ativo **pode** já direcionar o
item pra aquele mercado (atalho do "num mercado só"). *(detalhe fino, confirmar na impl.)*

**Pergunta 1 (economia vs preço na lista):** **DECIDIDO manter como está** — economia no
topo (foco) + preços individuais por item (a pessoa vê se um preço mudou e corrige nos Itens).

**Descartado (com motivo):**
- Modo "escolher comparar vs fixo" — comparador é padrão, sem escolha de modo imposta.
- "Fixar onde der" (aparece em todos os chips) — a decisão "recorrente ⇒ mercado" já mata
  o buraco de visibilidade que motivava isso.
- "Fixado comparável com soma/subtrai por preferência" — é só um comparável comum + nada
  novo; e "pagar mais caro de propósito" sujaria a métrica de economia.
- Recorrente-que-ainda-compara **não** é expressável (re-adiciona a cada compra pela busca).

**Impl. (esboço, quando for):** produto ganha `mercadoFixo?` (id) ; `fixado` (já existe)
vira "recorrente" e passa a **exigir** `mercadoFixo`. Grade de preço no editor colapsa
quando `mercadoFixo` setado. Filtro da aba Listas: item com `mercadoFixo` entra no chip
dele; recorrente não sai ao finalizar. ⚠️ Mexe na aba Itens → novos **screenshots** +
**AAB** novo pra loja.

---

## 2. Alternativas de login / recuperação de acesso (pergunta 3)  — `[FUTURO]`
*(2026-07-29)*

**Situação hoje:** login é **só Google** (google_sign_in nativo). **Não existe senha no
app** → "esqueci a senha" é **não-problema por construção**: se a pessoa esquece a senha
*do Google*, recupera em `accounts.google.com` (fluxo do próprio Google), não no nosso app.

**Risco real (não a senha):** quem **não tem conta Google** não consegue entrar; e os
dados ficam amarrados ao **UID da conta Google** — perder acesso à conta = perder dados.

**Opções pra quando fizer sentido:**
- **E-mail + senha (Firebase Auth):** habilita o "esqueci a senha" **nativo** do Firebase
  (e-mail de reset). Custo: mais atrito + suporte.
- **Magic link / login por e-mail (passwordless):** sem senha pra esquecer.
- **Login com Apple:** vira **obrigatório** ao ir pro **iOS** (regra da Apple se houver
  login de terceiros).
- **Uso anônimo + vincular depois:** deixa usar sem login e "plugar" o Google mais tarde
  (baixa a barreira de entrada).

**Melhorias baratas já com Google-only:**
- Mostrar o **e-mail logado** bem visível + **troca fácil de conta** (evita cair na conta
  Google errada e "sumir" os dados).
- Pensar em **export/backup** dos dados (defesa contra perda de acesso à conta).

**Recomendação:** manter **Google-only no lançamento** (mais simples, "esqueci a senha"
já resolvido por design). Revisitar ao ir pro **iOS** ou se testadores reclamarem de
precisar de conta Google.

---

## 3. Lembretes programáveis pelo usuário (notificações simples)  — `[FUTURO]`
*(2026-07-30 — ideia do usuário.)*

**Ideia:** o usuário programa lembretes simples, **recorrentes por dia da semana**, pra
não perder promoções/rotinas de compra. Ex.:
- "Terça = dia de promoção de frutas e verduras no **[Mercado X]**."
- "Quarta = dia da carne no **Açougue**."

**Conexão com o app:** casa direto com **"mercado dedicado / recorrente"** (seção 1) — a
ideia é lembrar de comprar algo **dedicado a um mercado**, e talvez puxar/relembrar os
**itens recorrentes** daquele mercado no dia.

**Esboço (a definir):** notificação **local** (sem servidor), agendada por **dia da semana
+ hora**; texto livre + opcional um mercado. Flutter: `flutter_local_notifications`; no
Android 13+ pede permissão `POST_NOTIFICATIONS`; cuidar de fuso e reagendar no boot. Sem
push/servidor no MVP. Provável tela/aba "Lembretes" (lista de regras semanais com on/off).

---

## 4. Diversos rondando  — `[FUTURO]` / `[ADIADO]`
- **Inglês (i18n):** lançar em PT; inglês depois, como atualização. `[FUTURO]`
- **Monetização:** grátis e **sem anúncios** no lançamento (decisão do usuário). AdMob ou
  premium = reabrir só bem depois. `[ADIADO]`
- **Molduras nos screenshots** da loja (device frames). `[FUTURO]`
- **BEM no futuro (Fase 4):** rede social + preços anônimos por bairro. `[FUTURO]`
