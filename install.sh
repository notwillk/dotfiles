#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$DIR/.bin/dotrules.sh" --rules "$DIR/rules.d" fix || true
