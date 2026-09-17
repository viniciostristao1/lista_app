# AGENTS.md — lista_app

## Ao finalizar qualquer melhoria
Quando o usuário pedir uma melhoria/feature/bugfix e o trabalho for concluído (commit + push em `main`):
1. Aguarde o workflow `Build APK` terminar ( `gh run list --repo viniciostristao1/lista_app --branch main --limit 1` ).
2. Entregue como resultado o **link direto do APK** da última versão (release rolling `ci-latest`):
   - **APK arm64 (recomendado):** `https://github.com/viniciostristao1/lista_app/releases/download/ci-latest/app-arm64-v8a-release.apk`
   - AAB: `https://github.com/viniciostristao1/lista_app/releases/download/ci-latest/app-release.aab`
3. Informe o commit e o link do run do Actions.

Não omita o link — o usuário espera o APK direto para instalar.

## Lançamento na Play Store (AAB) — NÃO é o fluxo normal de melhoria
> Melhoria/bugfix do dia a dia = fluxo acima (push → APK). O AAB só importa quando se quer
> **publicar na Play Store**. Aqui o CI (`build-apk.yml`) **já compila o AAB junto** a cada push
> e publica em `ci-latest/app-release.aab` — então o AAB está sempre atualizado; o que é **manual**
> é fazer o **upload no Play Console** (o usuário faz; Play revisa). Cada upload novo na Play exige
> `versionCode` (o `+N` do `pubspec`) maior. Pacote de loja (ficha/Data Safety/screenshots/política)
> em [`LANCAMENTO.md`](LANCAMENTO.md). Uma IA **não** publica na loja; no máximo gera/aponta o AAB.
