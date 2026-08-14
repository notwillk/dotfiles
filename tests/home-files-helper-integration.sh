#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HELPER="${REPO_ROOT}/features/default/scripts/stow-home-files"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-home-files-helper.XXXXXX")"
trap 'rm -rf "${TEST_ROOT}"' EXIT

fail() {
  printf '[tests/home-files-helper-integration.sh] %s\n' "$*" >&2
  exit 1
}

[[ -x "${HELPER}" ]] || fail "shared helper is not executable: ${HELPER}"
command -v stow >/dev/null 2>&1 || fail "GNU Stow is required"

home="${TEST_ROOT}/home"
conflict_home="${TEST_ROOT}/conflict-home"
mkdir -p "${home}" "${conflict_home}"

HOME="${home}" "${HELPER}" apply
HOME="${home}" "${HELPER}" check
[[ -L "${home}/managed_by_dofiles.md" ]] ||
  fail "helper apply did not create the managed marker"
[[ "$(readlink "${home}/managed_by_dofiles.md")" == *"/home/managed_by_dofiles.md" ]] ||
  fail "managed marker does not point into the home package"

unlink "${home}/managed_by_dofiles.md"
if HOME="${home}" "${HELPER}" check; then
  fail "helper check did not detect a missing managed link"
fi
HOME="${home}" "${HELPER}" apply
HOME="${home}" "${HELPER}" check

HOME="${home}" "${HELPER}" uninstall
[[ ! -e "${home}/managed_by_dofiles.md" && ! -L "${home}/managed_by_dofiles.md" ]] ||
  fail "helper uninstall left the managed marker"

printf 'unmanaged\n' >"${conflict_home}/managed_by_dofiles.md"
if HOME="${conflict_home}" "${HELPER}" apply; then
  fail "helper apply overwrote an unmanaged conflict"
fi
[[ "$(cat "${conflict_home}/managed_by_dofiles.md")" == "unmanaged" ]] ||
  fail "helper apply changed an unmanaged conflict"

printf '[tests/home-files-helper-integration.sh] Shared helper lifecycle passed.\n'
