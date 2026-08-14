#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CONFIG="${REPO_ROOT}/features/legacy/stow.rulesy.yaml"
HOME_CONFIG="${REPO_ROOT}/features/legacy/home-files.rulesy.yaml"
DEFAULT_CONFIG="${REPO_ROOT}/features/default/rulesy.yaml"
LEGACY_CONFIG="${REPO_ROOT}/features/legacy/rulesy.yaml"
DEFAULT_APPLY="${REPO_ROOT}/features/default/apply"
LEGACY_APPLY="${REPO_ROOT}/features/legacy/apply"
HELPER="${REPO_ROOT}/features/legacy/scripts/stow-home-files"

fail() {
  printf '[tests/stow-rulesy-contract.sh] %s\n' "$*" >&2
  exit 1
}

rule_block() {
  local heading="$1"

  awk -v heading="  - name: ${heading}" '
    $0 == heading { selected = 1; next }
    selected && /^  - name:/ { exit }
    selected { print }
  ' "${CONFIG}"
}

[[ "$(cat "${DEFAULT_CONFIG}")" == $'rules:\n  - remote: gpg.rulesy.yaml' ]] ||
  fail "default rulesy.yaml must contain only the GPG remote"
[[ "$(cat "${LEGACY_CONFIG}")" == $'rules:\n  - remote: stow.rulesy.yaml\n  - remote: home-files.rulesy.yaml' ]] ||
  fail "legacy rulesy.yaml must contain only the ordered Stow and home-files remotes"

[[ "$(cat "${HOME_CONFIG}")" == $'rules:\n  - name: Home files are linked from the active dof workspace\n    skip-if: |\n      ! command -v gpg >/dev/null 2>&1 ||\n        ! command -v stow >/dev/null 2>&1\n    check: ./scripts/stow-home-files check\n    fix: ./scripts/stow-home-files apply' ]] ||
  fail "home-files.rulesy.yaml does not have the expected guarded helper lifecycle"

if grep -Eiq '\bstow\b' "${DEFAULT_APPLY}"; then
  fail "features/default/apply must not contain direct Stow behavior"
fi
[[ -x "${LEGACY_APPLY}" ]] || fail "the legacy apply hook must be executable"

[[ -x "${HELPER}" ]] || fail "the shared Stow home-files helper must be executable"
grep -Fq -- '--simulate' "${HELPER}" || fail "helper check must simulate"
grep -Fq -- '--stow' "${HELPER}" || fail "helper check must use the stow action"
grep -Fq -- '--restow' "${HELPER}" || fail "helper apply must restow"
grep -Fq -- '--delete' "${HELPER}" || fail "helper must support safe deletion"
if grep -Fq -- '--adopt' "${HELPER}"; then
  fail "helper must never adopt unmanaged files"
fi

[[ "$(grep -c '^  - name: GNU Stow is installed with ' "${CONFIG}")" -eq 19 ]] ||
  fail "Stow configuration must contain Homebrew plus root/sudo rules for nine system managers"
[[ "$(grep -c '^    check: command -v stow >/dev/null 2>&1$' "${CONFIG}")" -eq 20 ]] ||
  fail "every Stow installer and the final invariant must check the exact executable"
[[ "$(grep -c '^      command -v stow >/dev/null 2>&1 ||$' "${CONFIG}")" -eq 19 ]] ||
  fail "every installer rule must skip when Stow already exists"
[[ "$(grep -c '^    fix: brew install stow$' "${CONFIG}")" -eq 1 ]] ||
  fail "Homebrew Stow repair must be an ordinary fix"
[[ "$(grep -c '^    interactive-fix: |$' "${CONFIG}")" -eq 9 ]] ||
  fail "every non-root system-manager repair must be interactive"
[[ "$(grep -c '^  - name: GNU Stow is available$' "${CONFIG}")" -eq 1 ]] ||
  fail "Stow configuration must finish with an availability invariant"

previous_line=0
prior_managers=()
while IFS='|' read -r label manager install_command; do
  root_heading="GNU Stow is installed with ${label} as root"
  sudo_heading="GNU Stow is installed with ${label} using sudo"
  root_line="$(grep -nFx "  - name: ${root_heading}" "${CONFIG}" | cut -d: -f1)"
  sudo_line="$(grep -nFx "  - name: ${sudo_heading}" "${CONFIG}" | cut -d: -f1)"

  [[ -n "${root_line}" && -n "${sudo_line}" && "${root_line}" -gt "${previous_line}" &&
    "${sudo_line}" -gt "${root_line}" ]] ||
    fail "Stow manager precedence or root/sudo ordering is incorrect at ${manager}"
  previous_line="${sudo_line}"

  root="$(rule_block "${root_heading}")"
  sudo="$(rule_block "${sudo_heading}")"

  grep -Fq "! command -v ${manager} >/dev/null 2>&1" <<<"${root}" ||
    fail "root rule for ${manager} does not skip when the manager is absent"
  grep -Fq "! command -v ${manager} >/dev/null 2>&1" <<<"${sudo}" ||
    fail "sudo rule for ${manager} does not skip when the manager is absent"
  grep -Fq '[[ "${EUID:-$(id -u)}" -ne 0 ]]' <<<"${root}" ||
    fail "root rule for ${manager} is not restricted to root"
  grep -Fq '[[ "${EUID:-$(id -u)}" -eq 0 ]]' <<<"${sudo}" ||
    fail "sudo rule for ${manager} is not restricted to non-root users"
  grep -Fq "${install_command}" <<<"${root}" ||
    fail "root rule for ${manager} has the wrong install command"
  grep -Fq "sudo ${install_command}" <<<"${sudo}" ||
    fail "sudo rule for ${manager} has the wrong install command"

  for higher_manager in "${prior_managers[@]}"; do
    grep -Fq "command -v ${higher_manager} >/dev/null 2>&1 ||" <<<"${root}" ||
      fail "root rule for ${manager} does not defer to ${higher_manager}"
    grep -Fq "command -v ${higher_manager} >/dev/null 2>&1 ||" <<<"${sudo}" ||
      fail "sudo rule for ${manager} does not defer to ${higher_manager}"
  done
  prior_managers+=("${manager}")
done <<'MANAGERS'
apt-get|apt-get|apt-get install -y stow
apt|apt|apt install -y stow
dnf|dnf|dnf install -y stow
yum|yum|yum install -y stow
pacman|pacman|pacman -Sy --noconfirm stow
zypper|zypper|zypper --non-interactive install stow
apk|apk|apk add stow
xbps-install|xbps-install|xbps-install -Sy stow
pkg|pkg|pkg install -y stow
MANAGERS

printf '[tests/stow-rulesy-contract.sh] Stow Rulesy contract passed.\n'
