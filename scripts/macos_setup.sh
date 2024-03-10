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

if ! command -v home-manager &> /dev/null
then
    echo "Installing home-manager..."
    nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
    nix-channel --update
    nix-shell '<home-manager>' -A install
else
    echo "Home-manager already installed."
fi


echo "Installing ~/.nixpkgs symlink..."
rm -rf "$HOME/.nixpkgs"
ln -s "$HOME/.dotfiles/nixpkgs" "$HOME/.nixpkgs"

echo "Installing ~/.config/home-manager symlink..."
rm -rf "$HOME/.config/home-manager"
ln -s "$HOME/.dotfiles/home-manager" "$HOME/.config/home-manager"
