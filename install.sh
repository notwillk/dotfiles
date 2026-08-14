#!/usr/bin/env bash
set -euo pipefail

DOF_INSTALL_URL="https://raw.githubusercontent.com/notwillk/dof/main/scripts/install.sh"
DOTFILES_REPOSITORY="https://github.com/notwillk/dotfiles.git"

fail() {
  printf '[install.sh] CRITICAL: %s\n' "$*" >&2
  exit 1
}

if [[ -z "${HOME:-}" ]]; then
  fail "HOME is not set; refusing to install dotfiles without a known target home."
fi

if [[ ! -d "${HOME}" ]]; then
  fail "HOME is set to '${HOME}', but that directory does not exist."
fi

DOF_BIN="${HOME}/.dof/bin/dof"
DOF_CONFIG_PATH="${HOME}/.dof/config.yaml"
DOF_WORKSPACE_PATH="${HOME}/.dof/workspace"
DEFAULT_SELECTION_PENDING_PATH="${HOME}/.dof/.default-selection-pending"
FRESH_DOF_STATE=0

if [[ ! -e "${DOF_CONFIG_PATH}" && ! -L "${DOF_CONFIG_PATH}" &&
  ! -e "${DOF_WORKSPACE_PATH}" && ! -L "${DOF_WORKSPACE_PATH}" ]]; then
  FRESH_DOF_STATE=1
fi

if [[ ! -x "${DOF_BIN}" ]]; then
  printf '[install.sh] Installing dof into %s...\n' "${HOME}/.dof/bin"
  curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    "${DOF_INSTALL_URL}" | DEST="${HOME}/.dof/bin" sh
fi

if [[ ! -x "${DOF_BIN}" ]]; then
  fail "dof installation completed without creating executable '${DOF_BIN}'."
fi

if [[ "${FRESH_DOF_STATE}" -eq 1 ]]; then
  : >"${DEFAULT_SELECTION_PENDING_PATH}"
fi

printf '[install.sh] Installing dotfiles workspace from %s...\n' "${DOTFILES_REPOSITORY}"
"${DOF_BIN}" clone "${DOTFILES_REPOSITORY}"

if [[ "${FRESH_DOF_STATE}" -eq 1 || -f "${DEFAULT_SELECTION_PENDING_PATH}" ]]; then
  printf '[install.sh] Selecting only the default feature for this fresh installation...\n'
  for feature in hostname legacy macos-gui; do
    "${DOF_BIN}" feature disable "${feature}"
  done
  rm -f "${DEFAULT_SELECTION_PENDING_PATH}"
fi

printf '[install.sh] Applying enabled dotfiles features...\n'
"${DOF_BIN}" apply

printf '[install.sh] Dotfiles installation completed successfully.\n'
