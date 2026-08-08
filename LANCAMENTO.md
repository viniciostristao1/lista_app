# Pacote de lançamento — Play Store

Tudo pronto pra preencher o Google Play Console. Copie e cole daqui.

## ⭐ Build canônico a subir (qual AAB usar)
> **Fonte de verdade do "app correto": o release mais recente no GitHub.**
> Todo push em `app/**` gera APK **e** AAB do mesmo commit (CI `build-apk.yml`).

**Duas versões em jogo (registro de 2026-07-30):**

- **B — `v0.13.0-teste16`** (commit `05b09b6`) → asset `lista-app-v0.13.0.aab`.
  **TESTADA pelo usuário ✅.** É o **fallback seguro** (última boa conhecida), guardada
  (release + tag + APK/AAB). Se A der problema, lança-se B.
  - Download: https://github.com/viniciostristao1/lista_app/releases/tag/v0.13.0-teste16
- **A — `v0.28.0-teste32`** (commit `e2704b4`) → asset `lista-app-v0.28.0.aab` — feature
  **"mercado dedicado"** + **âmbar** + **ícone do desenho do usuário** (âmbar degradê, maior) +
  títulos c/ símbolo + **estilo Flat** (Listas enxuta/alinhada; Itens compacta) + nome com
  **maiúscula** + **ajuste de fonte** (Menor ~13,5 / Normal ~15 / Maior ~17,7). É o **ALVO de
  lançamento**, **a verificar pelo usuário**.
  - APK+AAB: https://github.com/viniciostristao1/lista_app/releases/tag/v0.28.0-teste32
  - *(supera `v0.27.0-teste31`.)*

**Oficial de lançamento pretendida = A** (assim que o usuário testar e aprovar). Enquanto
A não é validada, o pronto-e-testado é **B** — e é o que se sobe se precisar publicar já.

- **NÃO usar** o AAB antigo do release `playstore-pacote-1` (26/07).
- **Regra:** ao cortar o build de A, preencher aqui o release/tag dele; o AAB a subir é o
  do **release mais recente aprovado**.

## Identidade
- **Título da loja (≤30):** `Lista e comparador de mercado`
- **Nome no ícone:** `Lista`
- **Package (permanente):** `com.vinyapps.lista_app`
- **Categoria sugerida:** Compras (Shopping)
- **Monetização:** Grátis, sem anúncios, sem compras no app.
- **E-mail de contato:** viniciostristao@gmail.com
- **Idiomas:** PT no lançamento; Inglês (internacionalização) depois, como atualização.

## Descrição curta (≤80 caracteres)
```
Lista de compras com comparador de preços entre mercados. Economize de verdade.
```

## Descrição completa
```
Lista organiza suas compras de supermercado e mostra onde cada item sai mais barato.

Cadastre seus produtos uma vez, registre o preço em cada mercado que você frequenta, e o app faz o resto: destaca o menor preço, calcula quanto você economiza e monta sua lista de compras em segundos.

O que você pode fazer:
• Montar sua lista de compras rapidinho, buscando itens que você já cadastrou.
• Comparar o preço do mesmo produto entre seus mercados favoritos.
• Ver quanto economiza pegando cada item no lugar mais barato.
• Filtrar a lista por mercado — saiba o que comprar em cada lugar.
• Fixar itens que você sempre compra (leite, pão…) pra eles não sumirem.
• Acompanhar o histórico de compras e quanto gastou/economizou por mês.
• Alerta quando um preço está desatualizado (mais de 30 dias), pra não confiar em preço velho.
• Calculadora para comparar produtos de pesos diferentes.
• Copiar a lista pra compartilhar no WhatsApp.

Seus dados ficam só com você, sincronizados na nuvem com login pelo Google. Sem anúncios.
```

## Data Safety (Segurança dos dados) — respostas
**O app coleta ou compartilha dados de usuário?** Sim, coleta (não compartilha com terceiros).

Dados coletados:
- **E-mail** — obrigatório · finalidade: gerenciamento da conta / login. (via Login Google)
- **Nome** — obrigatório · finalidade: gerenciamento da conta. (via Login Google)
- **Conteúdo do app** (as listas, itens, mercados, preços e histórico que o usuário cria)
  — obrigatório · finalidade: funcionalidade do app.

Perguntas do formulário:
- Dados **criptografados em trânsito**? **Sim** (Firebase usa HTTPS).
- Usuário pode **pedir exclusão** dos dados? **Sim** (por e-mail).
- Dados **compartilhados com terceiros**? **Não** (o Firebase/Google é provedor de
  infraestrutura, processa em nome do app; não é venda/compartilhamento).
- Coleta para **publicidade**? **Não.** Sem anúncios.
- App direcionado a **crianças**? **Não.**

## Política de privacidade
- **URL:** https://viniciostristao1.github.io/lista-privacidade/
- Hospedada no GitHub Pages (repo público `viniciostristao1/lista-privacidade`).

## Materiais gráficos
- **Ícone 512×512:** gerado (a partir de `assets/icon/icon_full.png`).
- **Feature graphic 1024×500:** gerado (`scratchpad/feature.png`).
- **Screenshots:** ✅ em `store/screenshots/` (01-listas, 02-itens, 03-pedidos, 04-busca).
  Usar 01, 02 e 03 (a 04 tem teclado na tela).

## Checklist do Play Console
- [x] Conta de desenvolvedor (US$25, CPF) — **paga + documentos enviados; AGUARDANDO
  verificação de identidade do Google** (situação em 2026-07-28).
- [ ] Criar app → preencher ficha (título/descrições/ícone/feature/screenshots).
- [ ] Data Safety (respostas acima).
- [ ] Classificação de conteúdo (questionário → "Livre").
- [ ] Política de privacidade (URL).
- [ ] Subir o **AAB** assinado → usar o **build canônico** do topo (`v0.13.0-teste16`
  → `lista-app-v0.13.0.aab`), NÃO o `playstore-pacote-1` antigo.
- [ ] Teste fechado: 20 testadores por 14 dias.
- [ ] Liberar produção.
```
