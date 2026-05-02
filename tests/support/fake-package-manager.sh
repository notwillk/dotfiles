#!/usr/bin/env bash
set -euo pipefail

manager="$(basename "$0")"

install_stow() {
  mkdir -p /usr/local/bin
  ln -sf /opt/test-stow/stow /usr/local/bin/stow
  echo "[${manager}] installed GNU Stow from test fixture"
}

case "${manager}" in
  brew)
    if [[ "${1:-}" == "install" && "${2:-}" == "stow" ]]; then
      install_stow
      exit 0
    fi
    ;;
  apt-get | apt)
    if [[ "${1:-}" == "update" ]]; then
      echo "[${manager}] update"
      exit 0
    fi

    if [[ "${1:-}" == "install" && "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  dnf | yum)
    if [[ "${1:-}" == "install" && "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  pacman)
    if [[ "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  zypper)
    if [[ "$*" == *"install"* && "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  apk)
    if [[ "${1:-}" == "add" && "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  xbps-install)
    if [[ "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
  pkg)
    if [[ "${1:-}" == "install" && "$*" == *"stow"* ]]; then
      install_stow
      exit 0
    fi
    ;;
esac

echo "[${manager}] unsupported test invocation: $*" >&2
exit 1
