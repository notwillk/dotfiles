ID="homelint-in-path"
DESCRIPTION="Ensure 'homelint' is installed"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
DOTFILES_BIN_PATH="$DOTFILES_PATH/bin"

# Detect the best rc file for this shell
_hl_detect_rc() {
  if [[ -n "${BASH_VERSION:-}" ]]; then
    RCFILE="$HOME/.bashrc"; SHELL_KIND="bash"
  elif [[ -n "${ZSH_VERSION:-}" ]]; then
    RCFILE="$HOME/.zshrc";  SHELL_KIND="zsh"
  else
    case "$(basename "${SHELL:-$0}")" in
      fish) RCFILE="$HOME/.config/fish/config.fish"; SHELL_KIND="fish" ;;
      bash) RCFILE="$HOME/.bashrc"; SHELL_KIND="bash" ;;
      zsh)  RCFILE="$HOME/.zshrc";  SHELL_KIND="zsh" ;;
      *)    RCFILE="$HOME/.profile"; SHELL_KIND="sh" ;;
    esac
  fi
}

# PASS if homelint is already available on PATH
check() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Checking if 'homelint' is available on PATH..."
  fi
  command -v homelint >/dev/null 2>&1;
}

can_fix() {
  VERBOSE="$1"
  if [[ "$VERBOSE" == "1" ]]; then
    echo "👀 Verifying the git repo exists"
  fi

  [ -d "$DOTFILES_BIN_PATH" ] && \
  [ -f "$DOTFILES_BIN_PATH/homelint" ] && \
  [ -x "$DOTFILES_BIN_PATH/homelint" ]
}

fix() {
  VERBOSE="$1"

  _hl_detect_rc
  if [[ "$VERBOSE" == "1" ]]; then
    echo "ℹ️ Detected shell kind: $SHELL_KIND"
    echo "ℹ️ Using rc file: $RCFILE"
  fi

  if [[ "$SHELL_KIND" == "fish" ]]; then
    line="set -x PATH $DOTFILES_BIN_PATH \$PATH"
  else
    line="export PATH=\$PATH:$DOTFILES_BIN_PATH"
  fi

  if ! grep -Fxq "$line" "$RCFILE"; then
    if [[ "$VERBOSE" == "1" ]]; then
      echo "✏️ Adding '$line' to $RCFILE"
    else
      echo "😲 '$line' already exists in $RCFILE"
    fi

    echo "$line" >> "$RCFILE"
  fi

}