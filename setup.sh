#!/usr/bin/env bash
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

if [ "$CODESPACES" == "true" ]; then
    source "$SCRIPTS_DIR/codespaces_setup.sh"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    source "$SCRIPTS_DIR/linux_setup.sh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    source "$SCRIPTS_DIR/macos_setup.sh"
else
    echo "Unknown OS ($OSTYPE)."
    exit 1
fi

echo "For best results, close this terminal and open a new one"
