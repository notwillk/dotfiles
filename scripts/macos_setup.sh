#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if ! command -v nix-env --version &> /dev/null
then
    echo "Installing nix in multi-user mode..."
    sh <(curl -L https://nixos.org/nix/install)
    echo "Re-run this script from a new shell..."
    exit 0
else
    echo "Nix already installed."
fi

if ! command -v darwin-rebuild &> /dev/null
then
    echo "Installing nix-darwin..."
    nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
    nix-channel --update
    pushd "$SCRIPT_DIR/.." > /dev/null
    nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
    ./result/bin/darwin-installer
    rm -rf "$SCRIPT_DIR/../result"
    popd > /dev/null
else
    echo "Nix-darwin already installed."
fi

if ! command -v brew &> /dev/null
then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew already installed."
fi

if test -f "$SCRIPT_DIR/scripts/switch.sh"
then
  echo "Configuring system..."
  "$SCRIPT_DIR/scripts/switch.sh"
else
  echo "Please clone the repo, and rerun this script to finish the installation."
fi
