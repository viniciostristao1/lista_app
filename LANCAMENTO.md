# Pacote de lançamento — Play Store (Save List)

Tudo pronto pra preencher o Google Play Console. **Copie e cole daqui.**
Atualizado em **2026-09-16** para o nome novo **"Save List"** (v0.44 / `1.0.0`).

> **Como ler este arquivo:** a parte de cima é **material** (textos e respostas prontos
> pra colar). A parte de baixo (**"② No Play Console — passo a passo"**) é o **roteiro do
> que só você consegue fazer** logado na sua conta. Eu (Claude) não tenho acesso ao Console;
> preparo os arquivos, você faz os cliques.

---

## ⭐ Build a subir (o AAB)

O que a Play Store recebe é um **AAB** (Android App Bundle), não o APK.

- **Arquivo:** `app-release.aab` (renomeei a cópia entregue como `SaveList-v1.0.0.aab`).
- **Versão embutida:** `versionName 1.0.0`, `versionCode 1` (primeira subida — o Google só
  exige que **cada nova subida tenha um número maior**; 1 é válido pra estrear).
- **Assinatura:** já vem assinado com a **chave de upload** oficial
  (SHA-1 `FB:02:95:85:16:45:D3:05:16:BA:58:08:38:EB:FD:2F:9E:23:C0:F0`, expira em 2053) —
  a mesma registrada no Firebase, então o **Login Google continua funcionando**.
- **De onde sai (sempre a versão mais nova do código):** o CI gera o AAB a cada push e
  publica no release rolling **`ci-latest`**:
  `https://github.com/viniciostristao1/lista_app/releases/download/ci-latest/app-release.aab`
  (repo privado → precisa estar logado no GitHub). Eu também **te entrego o arquivo direto**
  no chat pra você só arrastar pro Console.

> ⚠️ **Não** use AABs antigos (`playstore-pacote-1`, `lista-app-v0.13.0.aab`, `v0.32.0`) —
> são de antes do nome "Save List" e de dezenas de melhorias.

---

## Identidade da ficha

| Campo | Valor |
|---|---|
| **Nome do app (≤30):** | `Save List: lista de compras` |
| **Nome no ícone (launcher):** | `Save List` |
| **Package (permanente):** | `com.vinyapps.lista_app` |
| **Categoria:** | Compras (Shopping) |
| **Tags:** | lista de compras, supermercado, comparar preços |
| **Monetização:** | Grátis · sem anúncios · sem compras no app |
| **E-mail de contato:** | viniciostristao@gmail.com |
| **Idioma do lançamento:** | Português (Brasil). Inglês/Espanhol já existem no app; dá pra
adicionar as fichas traduzidas depois, como atualização. |

## Descrição curta (≤80 caracteres)
```
Lista de compras com comparador de preços entre mercados. Economize de verdade.
```

## Descrição completa (≤4000 caracteres)
```
Save List organiza suas compras de supermercado e mostra onde cada item sai mais barato.

Cadastre seus produtos uma vez, registre o preço em cada mercado que você frequenta, e o app faz o resto: destaca o menor preço, calcula quanto você economiza e monta sua lista em segundos.

O que você pode fazer:
• Montar sua lista de compras rapidinho, buscando itens que você já cadastrou.
• Comparar o preço do mesmo produto entre até 8 mercados favoritos.
• Ver quanto economiza pegando cada item no lugar mais barato.
• Abrir o app já no seu mercado favorito e filtrar a lista por mercado.
• Fixar itens que você sempre compra (leite, pão…) pra eles não sumirem.
• Anotar recados numa Nota rápida — que também vira uma lista de tarefas (to-do) marcável.
• Acompanhar o histórico de compras e quanto gastou/economizou por mês.
• Receber alerta quando um preço está desatualizado (mais de 30 dias).
• Comparar produtos de pesos diferentes na calculadora (preço por unidade).
• Copiar a lista pra compartilhar no WhatsApp.
• Escolher entre 4 temas (claro e escuro) e 3 idiomas (Português, Inglês, Espanhol).

Seus dados ficam só com você, sincronizados na nuvem com login pelo Google. Sem anúncios.
```

---

## Materiais gráficos

| Item | Especificação | Status |
|---|---|---|
| **Ícone** | 512×512 PNG, ≤1 MB | ✅ `store/icon_512.png` |
| **Feature graphic** | 1024×500 PNG/JPG | ✅ `store/feature_graphic.png` |
| **Screenshots (telefone)** | 2 a 8, lado 320–3840px, PNG 24-bit s/ alpha, ≤2:1 | ✅ 4 novos (16/09) |

**Screenshots prontos em `store/screenshots/`** (app atual "Save List", formatados p/ a loja —
proporção 1,98:1, RGB sem alpha):
1. `01-listas.png` — aba Listas (título "Save List", mercado favorito ⭐, "Economia 43%")
2. `02-comparador.png` — aba Itens: comparador de preço entre mercados ("economiza vs …")
3. `03-precos-por-mercado.png` — editar item: preço por mercado (a base do comparador)
4. `04-pedidos.png` — Pedidos: resumo do mês ("Em Agosto economizou R$ 153,64")

> Os PNGs **crus** do celular ficam em `store/screenshots/originais/` — servem de base pras
> **artes caprichadas** (moldura de celular + legendas) que dá pra fazer depois. Trocar
> screenshots na loja é edição de ficha: **não** exige novo AAB nem reinicia o teste de 14 dias.

---

## Data Safety (Segurança dos dados) — respostas prontas

**O app coleta ou compartilha dados?** Coleta (não compartilha com terceiros).

Dados coletados:
| Dado | Obrigatório? | Finalidade | Origem |
|---|---|---|---|
| **E-mail** | Sim | Gerenciar conta / login | Login Google |
| **Nome** | Sim | Gerenciar conta | Login Google |
| **Conteúdo do app** (listas, itens, mercados, preços, histórico) | Sim | Funcionalidade do app | Criado pelo usuário |

Perguntas do formulário:
- Dados **criptografados em trânsito**? **Sim** (Firebase usa HTTPS).
- Usuário pode **pedir exclusão** dos dados? **Sim** — página dedicada: https://viniciostristao1.github.io/lista-privacidade/exclusao.html (colar em Data Safety → "URL para exclusão de contas").
- Dados **compartilhados com terceiros**? **Não** (Firebase/Google é só infraestrutura, processa
  em nome do app; não é venda nem compartilhamento).
- Coleta para **publicidade**? **Não.** Sem anúncios.
- App direcionado a **crianças**? **Não.**

## Classificação de conteúdo (questionário IARC) — respostas prontas

Categoria do app no questionário: **Utilitário / Produtividade / Comunicação** (não é jogo).
Responda **NÃO** para: violência, conteúdo sexual, linguagem imprópria, drogas/álcool/tabaco,
jogos de azar/apostas, medo/terror. O app **não** compartilha localização, **não** tem
compras digitais, **não** tem conteúdo gerado por usuários exibido publicamente (cada um vê só
o seu). → Resultado esperado: **Livre / Classificação L (todos)**.

## Política de privacidade e Termos
- **Política de privacidade (obrigatória):** https://viniciostristao1.github.io/lista-privacidade/
- **Termos de uso (opcional na Play, mas já criados):** https://viniciostristao1.github.io/lista-privacidade/termos.html
- **Exclusão de conta e dados (Data Safety):** https://viniciostristao1.github.io/lista-privacidade/exclusao.html
- Hospedadas no GitHub Pages (repo público `viniciostristao1/lista-privacidade`).

---

## ② No Play Console — passo a passo (o que só VOCÊ faz)

Pré-requisito ✅: conta de desenvolvedor paga **e aprovada** (verificação de identidade OK).

1. **Criar o app** — Play Console → **Criar app** → nome `Save List: lista de compras`,
   idioma padrão Português (Brasil), tipo **App**, **Grátis**. Aceitar as declarações.

2. **Ficha da Play Store** (menu *Presença na loja → Ficha principal da Store*):
   colar **nome**, **descrição curta**, **descrição completa** (acima); subir **ícone 512**,
   **feature graphic** e **screenshots** (os novos). Salvar.

3. **Configuração do app** (menu *Política → App content*): preencher, um por um:
   - **Política de privacidade:** colar a URL.
   - **Anúncios:** *Não contém anúncios.*
   - **Acesso ao app:** *Todas as funções ficam disponíveis sem restrição* — **mas** o login é
     Google; forneça um **login de teste** OU explique que basta entrar com qualquer conta
     Google (o revisor precisa conseguir usar o app).
   - **Classificação de conteúdo:** responder o questionário (respostas acima) → gera "Livre".
   - **Público-alvo:** faixa etária **18+** ou **13+** (não é infantil) → responder que **não**
     é direcionado a crianças.
   - **Data safety:** preencher com a tabela acima.
   - **Apps de governo / finanças / saúde / COVID:** **Não** a todos.

4. **Teste fechado (obrigatório p/ contas novas)** — menu *Testes → Teste fechado*:
   - Criar uma faixa (track) de teste fechado, **subir o AAB** (`SaveList-v1.0.0.aab`).
   - Criar uma **lista de e-mails** com **pelo menos 12 testadores** (podem ser amigos/família;
     precisam **aceitar o convite** e **manter instalado**).
   - Compartilhar o **link de opt-in** com eles.
   - ⏳ **Regra do Google:** manter o teste rodando com ≥12 testadores por **14 dias seguidos**.
   - Depois dos 14 dias, aparece o botão **"Solicitar acesso à produção"**.

5. **Produção** — depois de aprovado o acesso: menu *Produção* → criar release → subir o mesmo
   (ou novo) AAB → escrever as **notas da versão** → enviar para revisão. A revisão do Google
   costuma levar de algumas horas a alguns dias.

> 💡 Ao subir o AAB pela 1ª vez, o Google vai oferecer o **Play App Signing** (recomendado,
> aceite): o Google guarda a chave de **assinatura do app** e você usa a de **upload**. Isso
> significa que, se um dia você perder a chave de upload, dá pra resetar — mas **guarde mesmo
> assim** o backup que te enviei (`upload-keystore.jks` + senha).

---

## Backup da chave (guardar em lugar seguro)
- `upload-keystore.jks` (alias `upload`) + **senha** — te enviei no chat. É o que assina os
  updates; sem ela (e sem Play App Signing) você não consegue atualizar o app. Guarde fora do
  celular (e-mail pra você mesmo, gerenciador de senhas, pendrive).

## Futuro — App Store (iOS)
- Precisa de: **conta Apple Developer** (US$99/ano), um **Mac** (ou serviço de build em nuvem,
  ex. Codemagic) pra compilar e assinar, ícones/screenshots no padrão da Apple e a mesma
  política de privacidade. O código Flutter já é multiplataforma; o trabalho é de
  build/assinatura/ficha. Fica pra uma fase própria depois do Android no ar.
