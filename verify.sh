#!/usr/bin/env bash
set -euo pipefail

on_exit() {
  local status="$?"

  if [[ "${status}" -ne 0 ]]; then
    printf '[verify.sh] Exiting with %s code\n' "${status}" >&2
  fi
}

trap on_exit EXIT

prepend_text() {
  local prefix="$1"

  awk -v p="$prefix" '{ print p " " $0; fflush(); }'
}

prepend() {
  local prefix="$1"; shift

  if command -v stdbuf >/dev/null 2>&1; then
    stdbuf -oL -eL "$@" 2>&1 | prepend_text "$prefix"
  elif command -v script >/dev/null 2>&1; then
    script -q /dev/null "$@" 2>&1 | prepend_text "$prefix"
  else
    "$@" 2>&1 | prepend_text "$prefix"
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
DOTFILES_SOURCE_PATH="${REPO_ROOT}/home"
CODEX_SOURCE_PATH="${DOTFILES_SOURCE_PATH}/.codex"
CODEX_TARGET_PATH="${HOME}/.codex"

if [[ ! -d "${DOTFILES_SOURCE_PATH}" ]]; then
  log "Expected Stow package directory '${DOTFILES_SOURCE_PATH}' does not exist." >&2
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

if ! command -v stow >/dev/null 2>&1; then
  log "GNU Stow is not installed. Cannot verify Stow-managed symlinks." >&2
  log "Run '${REPO_ROOT}/install.sh' first." >&2
  exit 1
fi

log "GNU Stow is installed: $(command -v stow)"

STOW_PACKAGE="${DOTFILES_SOURCE_PATH#"${REPO_ROOT}/"}"
STOW_VERBOSITY="${STOW_VERBOSITY:-${VERBOCITY:-1}}"
STOW_COMMAND=(
  stow
  "--verbose=${STOW_VERBOSITY}"
  --simulate
  --stow
  --dir "${REPO_ROOT}"
  --target "${HOME}"
  "${STOW_PACKAGE}"
)

log "Verifying links from '${DOTFILES_SOURCE_PATH}' in '${HOME}'..."
printf -v STOW_COMMAND_DISPLAY "%q " "${STOW_COMMAND[@]}"
log "Running \`${STOW_COMMAND_DISPLAY% }\`..."

set +e
STOW_OUTPUT="$("${STOW_COMMAND[@]}" 2>&1)"
STOW_STATUS="$?"
set -e

if [[ -n "${STOW_OUTPUT}" ]]; then
  printf '%s\n' "${STOW_OUTPUT}" | prepend_text "[stow]"
fi

if [[ "${STOW_STATUS}" -ne 0 ]]; then
  log "Stow reported an error while verifying dotfiles." >&2
  exit "${STOW_STATUS}"
fi

STOW_ACTION_OUTPUT="$(
  printf '%s\n' "${STOW_OUTPUT}" | awk '$0 != "WARNING: in simulation mode so not modifying filesystem."'
)"

if [[ -n "${STOW_ACTION_OUTPUT}" ]]; then
  log "Dotfiles are not fully linked. The simulated Stow run above shows pending changes." >&2
  log "Run '${REPO_ROOT}/install.sh' to apply them." >&2
  exit 1
fi

if ! verify_codex_config; then
  log "Dotfiles are not fully linked. Run '${REPO_ROOT}/install.sh' to apply them." >&2
  exit 1
fi

log "Dotfiles are correctly linked in '${HOME}'."
