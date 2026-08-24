# 🛒 Lista App

Lista de compras de supermercado — rápida, com **comparador de preço por mercado**,
histórico de pedidos e login Google. Feito em Flutter, dados na nuvem (Firebase).

---

## ⬇️ Baixar o app (celular Android)

**Link fixo — sempre a última versão** (é só clicar; não muda de endereço):

### 👉 https://github.com/viniciostristao1/lista_app/releases/latest/download/lista-app.apk

> Guarde esse link nos favoritos. Toda vez que eu publicar uma melhoria, **o mesmo link**
> já baixa a versão nova — não precisa copiar link novo. Instala por cima do que já tem;
> seus dados ficam na nuvem (login), não se perde nada.
>
> ℹ️ O repositório é **privado**, então o download pede que você esteja **logado no GitHub**
> (a mesma conta de sempre) — igual aos links que você já clicava. Se o link acima der
> "Not Found", é só abrir a **página de releases** e clicar no APK do topo:
> https://github.com/viniciostristao1/lista_app/releases/latest

**Versão atual (A):** `v0.43.0-teste48` — *Save List (nome + logo no título) + Nota rápida/recados com To-do marcável + abre já no mercado favorito ⭐ + PT/EN/ES + 4 temas.*
**Fallback testado (B):** `v0.13.0-teste16`.
Histórico completo do que mudou → [**ATUALIZACOES.md**](ATUALIZACOES.md).

---

## 🗂️ Mapa dos documentos

| Arquivo | Pra quê |
|---|---|
| [**INICIO.md**](INICIO.md) | Ponto de partida: estado atual, fluxo de trabalho, técnico. *(ler 1º)* |
| [**ATUALIZACOES.md**](ATUALIZACOES.md) | Changelog do usuário — o que mudou e o que re-testar (1 linha + data). |
| [**IDEIAS.md**](IDEIAS.md) | Planos futuros (fila pós-lançamento). |
| [**APRENDIZADOS.md**](APRENDIZADOS.md) | Diário técnico + gotchas (build, login, assinatura). |
| [**LANCAMENTO.md**](LANCAMENTO.md) | Pacote da Play Store (ficha, textos, screenshots). |

Pastas: `app/` (código Flutter) · `design/` (logos-fonte) · `store/` (ícone/screenshots da loja) ·
`scripts/` (automação) · `.github/` (CI que builda na nuvem).

---

## 🔁 Como sai uma versão nova (fluxo)

1. Ajusto o código em `app/` e rodo `flutter analyze lib/`.
2. `git commit` + `git push` → o **CI do GitHub** compila APK+AAB na nuvem e publica no
   release rolling **`ci-latest`** (a VPS é fraca demais pra compilar Android).
3. Quando o CI fica verde, corto o release com o helper:
   ```
   scripts/release.sh v0.33.0-teste38 "resumo do que mudou"
   ```
   Ele baixa o build e cria o release com o APK de **nome fixo** (`lista-app.apk`) —
   é o que faz o link acima apontar sempre pro mais novo.
4. Anoto 1 linha em `ATUALIZACOES.md` e atualizo a versão aqui no README.

> Detalhe do fluxo e regras (o que NÃO fazer) → [INICIO.md](INICIO.md#fluxo-de-mudança-harness).
