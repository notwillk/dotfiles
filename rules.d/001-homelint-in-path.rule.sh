ID="homelint-in-path"
DESCRIPTION="Ensure 'homelint' is installed"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"

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
check() { command -v homelint >/dev/null 2>&1; }

can_fix() {
  [ -d "$DOTFILES_PATH" ] && \
  [ -f "$DOTFILES_PATH/homelint" ] && \
  [ -x "$DOTFILES_PATH/homelint" ]
}

fix() {
  _hl_detect_rc

  if [[ "$SHELL_KIND" == "fish" ]]; then
    line="set -x PATH $DOTFILES_PATH \$PATH"
  else
    line="export PATH=\$PATH:$DOTFILES_PATH"
  fi

  if ! grep -Fxq "$line" "$RCFILE"; then
    echo "$line" >> "$RCFILE"
  fi

}