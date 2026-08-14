#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HELPER="${REPO_ROOT}/features/legacy/scripts/stow-home-files"
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
ambiguous_home="${TEST_ROOT}/ambiguous-home"
foreign_marker="${TEST_ROOT}/foreign/marker"
mkdir -p "${home}" "${conflict_home}" "${ambiguous_home}" "$(dirname "${foreign_marker}")"

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

printf 'foreign\n' >"${foreign_marker}"
ln -s "${foreign_marker}" "${ambiguous_home}/managed_by_dofiles.md"
if ambiguous_output="$(HOME="${ambiguous_home}" "${HELPER}" apply 2>&1)"; then
  fail "helper apply accepted an ambiguous legacy marker"
fi
grep -Fq "points outside a recognizable dotfiles checkout" <<<"${ambiguous_output}" ||
  fail "ambiguous marker failure omitted the ownership diagnostic"
grep -Fq "Remove or migrate that link manually before retrying dof apply." <<<"${ambiguous_output}" ||
  fail "ambiguous marker failure omitted the recovery guidance"
[[ -L "${ambiguous_home}/managed_by_dofiles.md" ]] ||
  fail "helper apply removed an ambiguous legacy marker"
[[ "$(readlink "${ambiguous_home}/managed_by_dofiles.md")" == "${foreign_marker}" ]] ||
  fail "helper apply changed an ambiguous legacy marker"

printf '[tests/home-files-helper-integration.sh] Shared helper lifecycle passed.\n'
