#!/usr/bin/env bash
set -euo pipefail

V="${VERSION:-latest}"
PREFIX="/usr/local"

if [ "$V" != "latest" ] && [ "$V" != "current" ]; then
  V="${V#v}"
fi

npm install -g --prefix "$PREFIX" "@openai/codex@${V}"

CODEX_JS="$(npm root -g --prefix "$PREFIX")/@openai/codex/bin/codex.js"

chmod +x "$CODEX_JS"
ln -sf "$CODEX_JS" "$PREFIX/bin/codex"

"$PREFIX/bin/codex" --version
