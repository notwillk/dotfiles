#!/usr/bin/env bash

if ! command -v nix-env --version &> /dev/null
then
    if [ "$CODESPACES" == "true" ]
    then
        echo "Installing nix in single user mode..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon --yes
    else
        echo "Installing nix in multi-user mode..."
        sh <(curl -L https://nixos.org/nix/install)
        echo "Re-run this script from a new shell..."
        exit 0
    fi
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
