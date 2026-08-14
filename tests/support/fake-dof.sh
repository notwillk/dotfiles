#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == features && "${2:-}" == --json ]]; then
  printf '%s\n' "${FAKE_DOF_FEATURES_JSON:-[\"default\",\"legacy\"]}"
  exit 0
fi

if [[ "${1:-}" != run || "${2:-}" != rulesy ]]; then
  printf 'unsupported test dof invocation: %s\n' "$*" >&2
  exit 1
fi

shift 2
exec "${HOME}/.dof/bin/rulesy" "$@"
