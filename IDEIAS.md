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

## 1. Mercado dedicado a um item (perguntas 1 + 2)  — `[EM DISCUSSÃO]`
*(2026-07-29 — formato ainda NÃO travado; vamos lapidar depois.)*

**Dor:** hoje o chip de mercado na aba Listas significa "onde está mais barato"
(derivado do comparador). Item sem preço não tem "mais barato" → cai só em "Todos".
Faltam dois casos:
- **(Q1) Perecível de mercado único** — quero fixar um produto a um mercado, **sem
  preço**, e que ele viva na sublista desse mercado (não só em "Todos").
- **(Q2) Item novo direcionado** — ao adicionar na lista, poder mandar direto pra um
  mercado específico, sem preço (o padrão hoje é cair em "Todos" sem preço — o que
  também é um **lembrete** válido e deve continuar existindo).

**Direção esboçada (a confirmar):**
- Cada item de lista tem um **"mercado efetivo"** resolvido em camadas de prioridade:
  1) escolha explícita ao adicionar → 2) "mercado fixo" do produto → 3) mais barato
  (atual) → 4) nenhum (só em "Todos").
- **"Todos" = superconjunto**; chips são recortes. Item direcionado ao X aparece em
  **Todos + X**. Nada some de "Todos".
- **Q1** = campo "Mercado fixo (opcional)" no produto (aba Itens); ao marcar, os campos
  de preço recolhem. Eixo diferente do `fixado` atual ("não sai ao finalizar") — os dois
  podem coexistir. Cuidar da **nomenclatura** ("Fixar na lista" vs "Mercado fixo").
- **Q2** = chips de destino **dentro do painel de adicionar** (padrão = filtro ativo),
  **sem** criar um segundo ícone/FAB. Preço segue opcional.
- **Decisão em aberto:** ao direcionar na lista um item vindo do catálogo, o produto no
  catálogo (a) não muda / (b) pergunta "sempre nesse mercado?" e promove pra mercado
  fixo. Voto atual: começar em **(a)**; (b) como refinamento.

**Próximo passo:** retomar o design, fechar o formato, então implementar como um pacote
só e mover pra `[FEITO]`.

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

## 3. Diversos rondando  — `[FUTURO]` / `[ADIADO]`
- **Inglês (i18n):** lançar em PT; inglês depois, como atualização. `[FUTURO]`
- **Monetização:** grátis e **sem anúncios** no lançamento (decisão do usuário). AdMob ou
  premium = reabrir só bem depois. `[ADIADO]`
- **Molduras nos screenshots** da loja (device frames). `[FUTURO]`
- **BEM no futuro (Fase 4):** rede social + preços anônimos por bairro. `[FUTURO]`
