#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Setup dotfiles for codespaces..."

echo "Installing gitconfig..."
cp "$SCRIPT_DIR/gitconfig" "$HOME/.gitconfig"

echo "Done."
