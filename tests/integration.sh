#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DOF_BIN="${DOF_BIN:-$(command -v dof || true)}"

fail() {
  printf '[tests/integration.sh] %s\n' "$*" >&2
  exit 1
}

[[ -x "${DOF_BIN}" ]] || fail "dof is required"
command -v git >/dev/null 2>&1 || fail "git is required"
command -v stow >/dev/null 2>&1 || fail "GNU Stow is required"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-integration.XXXXXX")"
trap 'rm -rf "${TEST_ROOT}"' EXIT

SNAPSHOT="${TEST_ROOT}/snapshot"
mkdir -p "${SNAPSHOT}"
(
  cd "${REPO_ROOT}"
  tar --exclude=.git --exclude=tmp -cf - .
) | tar -xf - -C "${SNAPSHOT}"

git -C "${SNAPSHOT}" init -q -b main
git -C "${SNAPSHOT}" config user.name "Dotfiles Tests"
git -C "${SNAPSHOT}" config user.email "dotfiles-tests@example.invalid"
git -C "${SNAPSHOT}" add .
git -C "${SNAPSHOT}" commit -q -m "Integration fixture"
SNAPSHOT_URL="file://${SNAPSHOT}"

assert_link_contains() {
  local path="$1"
  local expected="$2"

  [[ -L "${path}" ]] || fail "expected symlink: ${path}"
  [[ "$(readlink "${path}")" == *"${expected}"* ]] ||
    fail "expected ${path} to point into ${expected}"
}

run_bootstrap_test() {
  local home="${TEST_ROOT}/bootstrap-home"
  local fake_bin="${TEST_ROOT}/fake-bin"
  mkdir -p "${home}" "${fake_bin}"

  cat >"${fake_bin}/curl" <<'CURL'
#!/bin/sh
case "$*" in
  *https://raw.githubusercontent.com/notwillk/dof/main/scripts/install.sh*) ;;
  *) printf 'unexpected curl arguments: %s\n' "$*" >&2; exit 1 ;;
esac
cat <<'INSTALLER'
#!/bin/sh
set -eu
[ "$DEST" = "$HOME/.dof/bin" ]
mkdir -p "$DEST"
cat >"$DEST/dof" <<'DOF'
#!/bin/sh
printf '%s\n' "$*" >>"$HOME/dof-calls"
DOF
chmod 0755 "$DEST/dof"
INSTALLER
CURL
  chmod 0755 "${fake_bin}/curl"

  HOME="${home}" PATH="${fake_bin}:${PATH}" "${REPO_ROOT}/install.sh"
  [[ -x "${home}/.dof/bin/dof" ]] || fail "bootstrap did not install the home-local dof binary"
  [[ "$(sed -n '1p' "${home}/dof-calls")" == "clone https://github.com/notwillk/dotfiles.git" ]] ||
    fail "bootstrap did not clone the expected repository first"
  [[ "$(sed -n '2p' "${home}/dof-calls")" == "apply" ]] ||
    fail "bootstrap did not apply after clone"

  cat >"${fake_bin}/curl" <<'CURL'
#!/bin/sh
printf 'curl must not run when the requested dof binary exists\n' >&2
exit 99
CURL
  HOME="${home}" PATH="${fake_bin}:${PATH}" "${REPO_ROOT}/install.sh"
  [[ "$(wc -l <"${home}/dof-calls")" -eq 4 ]] ||
    fail "bootstrap rerun did not invoke clone and apply exactly once"

  local failure_home="${TEST_ROOT}/bootstrap-failure-home"
  mkdir -p "${failure_home}/.dof/bin"
  cat >"${failure_home}/.dof/bin/dof" <<'DOF'
#!/bin/sh
printf '%s\n' "$*" >>"$HOME/dof-calls"
if [ "$1" = clone ]; then
  exit 17
fi
DOF
  chmod 0755 "${failure_home}/.dof/bin/dof"
  if HOME="${failure_home}" PATH="${fake_bin}:${PATH}" "${REPO_ROOT}/install.sh"; then
    fail "bootstrap ignored a dof clone failure"
  fi
  [[ "$(wc -l <"${failure_home}/dof-calls")" -eq 1 ]] ||
    fail "bootstrap continued to apply after clone failed"

  if env -u HOME "${REPO_ROOT}/install.sh"; then
    fail "bootstrap accepted an unset HOME"
  fi
}

run_normal_home_test() {
  local home="${TEST_ROOT}/normal-home"
  mkdir -p "${home}/keep"
  printf 'unmanaged\n' >"${home}/keep/file"

  HOME="${home}" "${DOF_BIN}" clone "${SNAPSHOT_URL}"
  HOME="${home}" "${DOF_BIN}" apply

  [[ -f "${home}/.bashrc" && ! -L "${home}/.bashrc" ]] ||
    fail "initial .bashrc is not a regular file"
  assert_link_contains "${home}/managed_by_dofiles.md" ".dof/workspace/home"
  [[ "$(cat "${home}/keep/file")" == "unmanaged" ]] ||
    fail "apply changed an unrelated file"

  HOME="${home}" "${DOF_BIN}" apply
  assert_link_contains "${home}/managed_by_dofiles.md" ".dof/workspace/home"
  compgen -G "${home}/.dotfiles/backups/.bashrc.backup.*" >/dev/null ||
    fail "reapply did not back up the copied initial file"

  HOME="${home}" "${home}/.dof/workspace/verify.sh"
  mkdir -p "${home}/.dof/bin"
  cp "${DOF_BIN}" "${home}/.dof/bin/dof"
  HOME="${home}" bash --noprofile --rcfile "${home}/.bashrc" -i -c '[[ "$(command -v dof)" == "$HOME/.dof/bin/dof" ]]'

  HOME="${home}" "${home}/.dof/workspace/uninstall.sh"
  [[ ! -e "${home}/managed_by_dofiles.md" && ! -L "${home}/managed_by_dofiles.md" ]] ||
    fail "uninstall left the managed marker link"
  [[ -f "${home}/.bashrc" && -x "${home}/.dof/bin/dof" ]] ||
    fail "uninstall removed copied files or dof"
}

run_symlinked_codex_test() {
  local home="${TEST_ROOT}/codex-home"
  local external="${TEST_ROOT}/codex-external"
  mkdir -p "${home}" "${external}"
  ln -s "${external}" "${home}/.codex"

  HOME="${home}" "${DOF_BIN}" clone "${SNAPSHOT_URL}"
  HOME="${home}" "${DOF_BIN}" apply
  assert_link_contains "${external}/config.toml" ".dof/workspace/home/.codex/config.toml"
}

run_legacy_handoff_test() {
  local home="${TEST_ROOT}/legacy-home"
  mkdir -p "${home}"

  HOME="${home}" "${SNAPSHOT}/default/apply"
  assert_link_contains "${home}/managed_by_dofiles.md" "/snapshot/home"

  HOME="${home}" "${DOF_BIN}" clone "${SNAPSHOT_URL}"
  HOME="${home}" "${DOF_BIN}" apply
  assert_link_contains "${home}/managed_by_dofiles.md" ".dof/workspace/home"
  assert_link_contains "${home}/.codex/config.toml" ".dof/workspace/home/.codex/config.toml"
}

run_ambiguous_legacy_test() {
  local home="${TEST_ROOT}/ambiguous-home"
  local unrelated="${TEST_ROOT}/unrelated-marker"
  mkdir -p "${home}"
  printf 'unrelated\n' >"${unrelated}"
  ln -s "${unrelated}" "${home}/managed_by_dofiles.md"

  HOME="${home}" "${DOF_BIN}" clone "${SNAPSHOT_URL}"
  if HOME="${home}" "${DOF_BIN}" apply; then
    fail "apply accepted an ambiguous legacy marker"
  fi
  [[ -L "${home}/managed_by_dofiles.md" && ! -e "${home}/.bashrc" ]] ||
    fail "ambiguous handoff changed the home before failing"
}

run_bootstrap_test
run_normal_home_test
run_symlinked_codex_test
run_legacy_handoff_test
run_ambiguous_legacy_test

printf '[tests/integration.sh] All integration tests passed.\n'
