#!/usr/bin/env bash

if ! command -v nix-env --version &> /dev/null
then
    if [ "$CODESPACES" == "true" ]
    then
        sh <(curl -L https://nixos.org/nix/install) --no-daemon --yes
    else
        sh <(curl -L https://nixos.org/nix/install)
        echo "Re-run this script from a new shell..."
        exit 0
    fi
fi

