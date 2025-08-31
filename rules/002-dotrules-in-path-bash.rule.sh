COMMAND_NAME="dotrules"
ID="$COMMAND_NAME-in-path-bash"
DESCRIPTION="Ensure '$COMMAND_NAME' is installed (bash)"
SKIP_VALIDATE_AFTER_FIX="true"

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
DOTFILES_BIN_PATH="${DOTFILES_BIN_PATH:-$DOTFILES_PATH/bin}"

RCFILE="$HOME/.bashrc"

applies() {
  local VERBOSE="${1:-0}"

  if [[ -n "${BASH_VERSION:-}" ]] || [[ "$(basename -- "${SHELL:-$0}")" = "bash" ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

check() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Checking if '$COMMAND_NAME' is available on PATH..."
  fi
  command -v $COMMAND_NAME >/dev/null 2>&1;
}

can_fix() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Verifying the git repo exists"
  fi

  [ -d "$DOTFILES_BIN_PATH" ] && [ -f "$DOTFILES_BIN_PATH/$COMMAND_NAME" ] && [ -x "$DOTFILES_BIN_PATH/$COMMAND_NAME" ]
}

fix() {
  VERBOSE="$1"

  line="export PATH=\$PATH:$DOTFILES_BIN_PATH"

  if ! grep -Fxq "$line" "$RCFILE"; then
    if [[ "$VERBOSE" == "1" ]]; then
      echo "✏️ Adding '$line' to $RCFILE"
    fi

    echo "$line" >> "$RCFILE"
  else
    echo "😲 '$line' already exists in $RCFILE"
  fi

}