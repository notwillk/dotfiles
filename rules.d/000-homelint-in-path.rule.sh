ID="homelint-in-path"
DESC="Ensure 'homelint' is installed and on PATH"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect the best rc file for this shell
_hl_detect_rc() {
  # prefer the *running* shell, then login shell
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

# Rule applies everywhere (we always want homelint available)
applies() { return 0; }

# PASS if homelint is already available on PATH
check() { command -v homelint >/dev/null 2>&1; }

# We can fix if we can read a source file and write to HOME/rc
can_fix() {
  _hl_detect_rc

  # Where to copy homelint from:
  # - allow override via HOMELINT_SRC
  # - otherwise assume it's next to rules (repo root): $DIR/homelint
  local src="${HOMELINT_SRC:-$DIR/../homelint}"

  [[ -r "$src" ]] || return 1
  # can we create ~/.bin?
  mkdir -p "$HOME/.bin" 2>/dev/null || return 1
  # can we create the rc file (or at least its parent dir)?
  mkdir -p "$(dirname "$RCFILE")" 2>/dev/null || true
  # touch to ensure it exists / is writable
  (touch "$RCFILE" 2>/dev/null) || return 1
}

fix() {
  _hl_detect_rc
  local src="${HOMELINT_SRC:-$DIR/../homelint}"
  local dest="$HOME/.bin/homelint"

  # 1) Ensure ~/.bin exists and copy the tool
  mkdir -p "$HOME/.bin"
  # use install to set mode; fall back to cp if install missing
  if command -v install >/dev/null 2>&1; then
    install -m 0755 "$src" "$dest"
  else
    cp -f "$src" "$dest" && chmod 0755 "$dest"
  fi

  # 2) Ensure ~/.bin is on PATH in the detected rc file (idempotent)
  case "$SHELL_KIND" in
    fish)
      # add only if not already present
      if ! grep -Eq '(^|\s)\$HOME/\.bin(\s|$)|\~/.bin' "$RCFILE"; then
        cat >>"$RCFILE" <<'EOF'

# homelint: ensure ~/.bin on PATH
if test -d "$HOME/.bin"
  set -gx PATH $HOME/.bin $PATH
end
EOF
      fi
      ;;
    *)
      # bash/zsh/sh
      if ! grep -Eq 'PATH=.*\$HOME/\.bin|PATH=.*\~/.bin' "$RCFILE"; then
        cat >>"$RCFILE" <<'EOF'

# homelint: ensure ~/.bin on PATH
if [ -d "$HOME/.bin" ]; then
  case ":$PATH:" in
    *":$HOME/.bin:"*) : ;;
    *) export PATH="$HOME/.bin:$PATH" ;;
  esac
fi
EOF
      fi
      ;;
  esac
}