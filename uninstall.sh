#!/usr/bin/env bash
set -euo pipefail

on_exit() {
  local status="$?"

  if [[ "${status}" -ne 0 ]]; then
    printf '[uninstall.sh] Exiting with %s code\n' "${status}" >&2
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
  prepend "[uninstall.sh]" echo "$@"
}

echo "              _            _ _ _ _          _       _    __ _ _           "
echo "  _ __   ___ | |___      _(_) | | | __   __| | ___ | |_ / _(_) | ___  ___ "
echo " | '_ \ / _ \| __\ \ /\ / / | | | |/ /  / _\` |/ _ \| __| |_| | |/ _ \/ __|"
echo " | | | | (_) | |_ \ V  V /| | | |   <  | (_| | (_) | |_|  _| | |  __/\__ \\"
echo " |_| |_|\___/ \__| \_/\_/ |_|_|_|_|\_\  \__,_|\___/ \__|_| |_|_|\___||___/"
echo "                                                                          "

if [[ -z "${HOME:-}" ]]; then
  log "HOME is not set. Refusing to continue because dotfiles must target a known home directory." >&2
  log "Run this script as the user whose home directory should be unmanaged, without clearing HOME." >&2
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

if [[ ! -d "${DOTFILES_SOURCE_PATH}" ]]; then
  log "Expected Stow package directory '${DOTFILES_SOURCE_PATH}' does not exist." >&2
  exit 1
fi

if ! command -v stow >/dev/null 2>&1; then
  log "GNU Stow is not installed. Cannot remove Stow-managed symlinks." >&2
  log "Install GNU Stow first, then rerun this script." >&2
  exit 1
fi

log "GNU Stow is installed: $(command -v stow)"

STOW_PACKAGE="${DOTFILES_SOURCE_PATH#"${REPO_ROOT}/"}"
STOW_VERBOSITY="${STOW_VERBOSITY:-${VERBOCITY:-2}}"
STOW_COMMAND=(
  stow
  "--verbose=${STOW_VERBOSITY}"
  --delete
  --dir "${REPO_ROOT}"
  --target "${HOME}"
  "${STOW_PACKAGE}"
)

log "Removing links from '${DOTFILES_SOURCE_PATH}' in '${HOME}'..."
printf -v STOW_COMMAND_DISPLAY "%q " "${STOW_COMMAND[@]}"
log "Running \`${STOW_COMMAND_DISPLAY% }\`..."
prepend "[stow]" "${STOW_COMMAND[@]}"
log "Dotfiles symlinks removed from '${HOME}'."
log "GNU Stow was not uninstalled."
