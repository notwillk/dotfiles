#!/usr/bin/env bash
set -euo pipefail

on_exit() {
  local status="$?"

  if [[ "${status}" -ne 0 ]]; then
    printf '[install.sh] Exiting with %s code\n' "${status}" >&2
  fi
}

trap on_exit EXIT

prepend() {
  local prefix="$1"; shift

  # pick strategy
  if command -v stdbuf >/dev/null 2>&1; then
    # Linux: force line buffering
    stdbuf -oL -eL "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  elif command -v script >/dev/null 2>&1; then
    # cross-platform fallback (macOS, etc.)
    script -q /dev/null "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  else
    # last resort (no buffering guarantees)
    "$@" 2>&1 | awk -v p="$prefix" '{ print p " " $0; fflush(); }'
  fi
}

log() {
  prepend "[install.sh]" echo "$@"
}

echo "              _            _ _ _ _          _       _    __ _ _           "
echo "  _ __   ___ | |___      _(_) | | | __   __| | ___ | |_ / _(_) | ___  ___ "
echo " | '_ \ / _ \| __\ \ /\ / / | | | |/ /  / _\` |/ _ \| __| |_| | |/ _ \/ __|"
echo " | | | | (_) | |_ \ V  V /| | | |   <  | (_| | (_) | |_|  _| | |  __/\__ \\"
echo " |_| |_|\___/ \__| \_/\_/ |_|_|_|_|\_\  \__,_|\___/ \__|_| |_|_|\___||___/"
echo "                                                                          "

if [[ -z "${HOME:-}" ]]; then
  log "HOME is not set. Refusing to continue because dotfiles must target a known home directory." >&2
  log "Run this script as the user whose home directory should be managed, without clearing HOME." >&2
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

if command -v stow >/dev/null 2>&1; then
  log "GNU Stow is installed: $(command -v stow)"
else
  SUDO=()

  require_sudo() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
      SUDO=()
    elif command -v sudo >/dev/null 2>&1; then
      SUDO=(sudo)
    else
      log "GNU Stow is not installed, and sudo is unavailable." >&2
      log "Please install GNU Stow manually or run this script as root." >&2
      exit 1
    fi
  }

  install_with() {
    local manager="$1"

    log "GNU Stow is not installed. Installing with ${manager}..."

    case "${manager}" in
      brew)
        brew install stow
        ;;
      apt-get)
        require_sudo
        "${SUDO[@]}" apt-get update
        "${SUDO[@]}" apt-get install -y stow
        ;;
      apt)
        require_sudo
        "${SUDO[@]}" apt update
        "${SUDO[@]}" apt install -y stow
        ;;
      dnf)
        require_sudo
        "${SUDO[@]}" dnf install -y stow
        ;;
      yum)
        require_sudo
        "${SUDO[@]}" yum install -y stow
        ;;
      pacman)
        require_sudo
        "${SUDO[@]}" pacman -Sy --noconfirm stow
        ;;
      zypper)
        require_sudo
        "${SUDO[@]}" zypper --non-interactive install stow
        ;;
      apk)
        require_sudo
        "${SUDO[@]}" apk add stow
        ;;
      xbps-install)
        require_sudo
        "${SUDO[@]}" xbps-install -Sy stow
        ;;
      pkg)
        require_sudo
        "${SUDO[@]}" pkg install -y stow
        ;;
      *)
        log "Unsupported package manager: ${manager}" >&2
        exit 1
        ;;
    esac
  }

  for manager in brew apt-get apt dnf yum pacman zypper apk xbps-install pkg; do
    if command -v "${manager}" >/dev/null 2>&1; then
      install_with "${manager}"
      break
    fi
  done

  if ! command -v stow >/dev/null 2>&1; then
    log "Failed to install GNU Stow." >&2
    log "Supported managers: brew, apt-get, apt, dnf, yum, pacman, zypper, apk, xbps-install, pkg." >&2
    exit 1
  fi

  log "GNU Stow installed: $(command -v stow)"
fi

GIT_PATH="git@github.com:notwillk/dotfiles.git"

STOW_PACKAGE="${DOTFILES_SOURCE_PATH#"${REPO_ROOT}/"}"
STOW_VERBOSITY="${STOW_VERBOSITY:-${VERBOCITY:-1}}"
STOW_COMMAND=(
  stow
  "--verbose=${STOW_VERBOSITY}"
  --restow
  --dir "${REPO_ROOT}"
  --target "${HOME}"
  "${STOW_PACKAGE}"
)

log "Linking '${DOTFILES_SOURCE_PATH}' into '${HOME}'..."
printf -v STOW_COMMAND_DISPLAY "%q " "${STOW_COMMAND[@]}"
log "Running \`${STOW_COMMAND_DISPLAY% }\`..."
prepend "[stow]" "${STOW_COMMAND[@]}"
log "Dotfiles successfully linked."
log "Make updates to ${GIT_PATH}"
log "Uninstall by running \`${REPO_ROOT}/uninstall.sh\`"
