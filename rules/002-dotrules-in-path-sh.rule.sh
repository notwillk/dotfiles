ID="dotrules-in-path-sh"
DESCRIPTION="Ensure 'dotrules' is installed (sh)"
SKIP_VALIDATE_AFTER_FIX="true"

DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
DOTFILES_BIN_PATH="${DOTFILES_BIN_PATH:-$DOTFILES_PATH/bin}"

RCFILE="$HOME/.profile"

applies() {
  case "$(basename -- "${SHELL:-}")" in
    bash|fish|zsh) return 1 ;;
    *) return 0 ;;
  esac
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
