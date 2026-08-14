#!/usr/bin/env bash
set -euo pipefail

on_exit() {
  local status="$?"

  if [[ "${status}" -ne 0 ]]; then
    printf '[verify.sh] Exiting with %s code\n' "${status}" >&2
  fi
}

trap on_exit EXIT

prepend() {
  local prefix="$1"; shift

  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  elif command -v script >/dev/null 2>&1; then
    script -q /dev/null "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  else
    "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  fi
}

log() {
  prepend "[verify.sh]" echo "$@"
}

echo "              _            _ _ _ _          _       _    __ _ _           "
echo "  _ __   ___ | |___      _(_) | | | __   __| | ___ | |_ / _(_) | ___  ___ "
echo " | '_ \ / _ \| __\ \ /\ / / | | | |/ /  / _\` |/ _ \| __| |_| | |/ _ \/ __|"
echo " | | | | (_) | |_ \ V  V /| | | |   <  | (_| | (_) | |_|  _| | |  __/\__ \\"
echo " |_| |_|\___/ \__| \_/\_/ |_|_|_|_|\_\  \__,_|\___/ \__|_| |_|_|\___||___/"
echo "                                                                          "

if [[ -z "${HOME:-}" ]]; then
  log "HOME is not set. Refusing to continue because dotfiles must target a known home directory." >&2
  log "Run this script as the user whose home directory should be verified, without clearing HOME." >&2
  exit 1
fi

if [[ ! -d "${HOME}" ]]; then
  log "HOME is set to '${HOME}', but that directory does not exist." >&2
  log "Run this script with HOME set to the current user's home directory." >&2
  exit 1
fi

ACCOUNT_HOME=""
if command -v getent >/dev/null 2>&1; then
  ACCOUNT_HOME="$(getent passwd "$(id -un)" | cut -d: -f6 || true)"
elif command -v dscl >/dev/null 2>&1; then
  ACCOUNT_HOME="$(dscl . -read "/Users/$(id -un)" NFSHomeDirectory 2>/dev/null | awk '{print $2}' || true)"
fi

if [[ -n "${ACCOUNT_HOME}" && "${HOME}" != "${ACCOUNT_HOME}" ]]; then
  log Warning: "HOME is set to '${HOME}', but the current user's home directory is '${ACCOUNT_HOME}'." >&2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_PAYLOAD_PATH="${REPO_ROOT}/home"
HOME_FILES_HELPER="${REPO_ROOT}/features/default/scripts/stow-home-files"
CODEX_SOURCE_PATH="${HOME_PAYLOAD_PATH}/.codex"
CODEX_TARGET_PATH="${HOME}/.codex"

if [[ ! -d "${HOME_PAYLOAD_PATH}" ]]; then
  log "Expected home payload directory '${HOME_PAYLOAD_PATH}' does not exist." >&2
  exit 1
fi

if [[ ! -x "${HOME_FILES_HELPER}" ]]; then
  log "Expected home-files helper '${HOME_FILES_HELPER}' is not executable." >&2
  exit 1
fi

verify_codex_config() {
  local source_file="${CODEX_SOURCE_PATH}/config.toml"
  local target_file="${CODEX_TARGET_PATH}/config.toml"

  if [[ ! -f "${source_file}" ]]; then
    return
  fi

  if [[ ! -L "${target_file}" ]]; then
    log "Codex config is not linked: ${target_file}" >&2
    return 1
  fi

  local current_target
  current_target="$(readlink "${target_file}")"

  if [[ "${current_target}" != "${source_file}" ]]; then
    log "Codex config points to '${current_target}', expected '${source_file}'." >&2
    return 1
  fi

  log "Codex config is correctly linked: ${target_file}"
}

log "Verifying managed home links in '${HOME}'..."
if ! "${HOME_FILES_HELPER}" check; then
  log "Home files are not fully linked. Run '${HOME}/.dof/bin/dof apply' to apply them." >&2
  exit 1
fi

if ! verify_codex_config; then
  log "Dotfiles are not fully linked. Run '${HOME}/.dof/bin/dof apply' to apply them." >&2
  exit 1
fi

log "Dotfiles are correctly linked in '${HOME}'."
