ID="dotrules-in-path-fish"
DESCRIPTION="Ensure 'dotrules' is installed (fish)"

RCFILE="$HOME/.config/fish/config.fish"

applies() {
  VERBOSE="$1"
  if [[ "$(basename -- "${SHELL:-$0}")" = "fish" ]]; then
    return 0  # true
  else
    return 1  # false
  fi
}

check() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Checking if 'dotrules' is available on PATH..."
  fi
  command -v dotrules >/dev/null 2>&1;
}

can_fix() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Verifying the git repo exists"
  fi

  [ -d "$DOTFILES_BIN_PATH" ] && \
  [ -f "$DOTFILES_BIN_PATH/dotrules" ] && \
  [ -x "$DOTFILES_BIN_PATH/dotrules" ]
}

fix() {
  VERBOSE="$1"

  line="set -x PATH $DOTFILES_BIN_PATH \$PATH"

  if ! grep -Fxq "$line" "$RCFILE"; then
    if [[ "$VERBOSE" == "1" ]]; then
      echo "✏️ Adding '$line' to $RCFILE"
    fi

    echo "$line" >> "$RCFILE"
  else
    echo "😲 '$line' already exists in $RCFILE"
  fi

}
