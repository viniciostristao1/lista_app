# AGENTS.md — lista_app

## Ao finalizar qualquer melhoria
Quando o usuário pedir uma melhoria/feature/bugfix e o trabalho for concluído (commit + push em `main`):
1. Aguarde o workflow `Build APK` terminar ( `gh run list --repo viniciostristao1/lista_app --branch main --limit 1` ).
2. Entregue como resultado o **link direto do APK** da última versão (release rolling `ci-latest`):
   - **APK arm64 (recomendado):** `https://github.com/viniciostristao1/lista_app/releases/download/ci-latest/app-arm64-v8a-release.apk`
   - AAB: `https://github.com/viniciostristao1/lista_app/releases/download/ci-latest/app-release.aab`
3. Informe o commit e o link do run do Actions.

Não omita o link — o usuário espera o APK direto para instalar.
