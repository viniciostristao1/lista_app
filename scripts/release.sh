#!/usr/bin/env bash
# release.sh — corta um release de teste a partir do build mais recente do CI.
#
# Uso:
#   scripts/release.sh <versao> "<nota de changelog em 1 linha>"
#   ex: scripts/release.sh v0.33.0-teste38 "Rótulos curtos + categoria mais colada"
#
# Pré-requisito: o commit já foi PUSHADO e o CI ficou VERDE (o build publica em
# 'ci-latest'). Rode:  gh run watch <id> --exit-status   antes de chamar isto.
#
# O que faz:
#   1. baixa o APK arm64 + AAB do release rolling 'ci-latest';
#   2. cria o release <versao> com QUATRO assets:
#        - lista-app-<num>-arm64.apk  (versionado, p/ clareza no histórico)
#        - lista-app-<num>.aab        (versionado, p/ Play Store)
#        - lista-app.apk              (NOME FIXO → link sempre-a-última)
#        - lista-app.aab              (NOME FIXO)
#
# O nome fixo faz o link abaixo apontar SEMPRE pro APK mais novo (sem trocar de URL):
#   https://github.com/viniciostristao1/lista_app/releases/latest/download/lista-app.apk
set -euo pipefail
REPO=viniciostristao1/lista_app

VER="${1:?uso: scripts/release.sh <versao> \"<nota>\"  (ex: v0.33.0-teste38)}"
NOTA="${2:-$VER}"
NUM="${VER#v}"; NUM="${NUM%%-*}"   # "0.33.0" a partir de "v0.33.0-teste38"

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

echo "→ Baixando o build de 'ci-latest'…"
gh release download ci-latest -R "$REPO" \
  -p app-arm64-v8a-release.apk -p app-release.aab --clobber

# sanidade: APK íntegro, assinado (v2) e arm64
unzip -t app-arm64-v8a-release.apk >/dev/null || { echo "APK corrompido"; exit 1; }
grep -aq 'APK Sig Block 42' app-arm64-v8a-release.apk || { echo "APK sem assinatura v2"; exit 1; }

cp app-arm64-v8a-release.apk "lista-app-${NUM}-arm64.apk"
cp app-release.aab           "lista-app-${NUM}.aab"
cp app-arm64-v8a-release.apk "lista-app.apk"    # NOME FIXO (link /latest/download)
cp app-release.aab           "lista-app.aab"     # NOME FIXO

echo "→ Criando release ${VER}…"
gh release create "$VER" -R "$REPO" --title "$VER" --notes "$NOTA" \
  "lista-app-${NUM}-arm64.apk" "lista-app-${NUM}.aab" "lista-app.apk" "lista-app.aab"

echo
echo "✓ Release ${VER} publicado."
echo "  APK (esta versão): https://github.com/$REPO/releases/download/$VER/lista-app-${NUM}-arm64.apk"
echo "  APK SEMPRE-A-ÚLTIMA (link fixo p/ o usuário):"
echo "      https://github.com/$REPO/releases/latest/download/lista-app.apk"
