#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ "$CODESPACES" == "true" ]
then
    source "$SCRIPT_DIR/codespaces_setup.sh"
    exit 0
fi

if ! command -v nix-env --version &> /dev/null
then
    echo "Installing nix in multi-user mode..."
    sh <(curl -L https://nixos.org/nix/install)
    echo "Re-run this script from a new shell..."
    exit 0
else
    echo "Nix already installed."
fi

if ! command -v home-manager &> /dev/null
then
    echo "Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
else
    echo "Home-manager already installed."
fi

rm -rf "$HOME/.config/home-manager"
ln -s "$HOME/.dotfiles/home-manager" "$HOME/.config/home-manager"
