#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != run || "${2:-}" != rulesy ]]; then
  printf 'unsupported test dof invocation: %s\n' "$*" >&2
  exit 1
fi

shift 2
exec "${HOME}/.dof/bin/rulesy" "$@"
