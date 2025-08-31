ID="dotfiles-cloned"
DESCRIPTION="Ensure dotfiles is cloned"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
REPOSITORY_URL="https://github.com/notwillk/dotfiles.git"

check() {
  VERBOSE="$1"
  if [ -d "$DOTFILES_PATH" ] && [ -d "$DOTFILES_PATH/.git" ]; then
    [[ $VERBOSE -eq 1 ]] && echo "Requisite paths exist" || true;
    local origin
    origin=$(git -C "$DOTFILES_PATH" remote get-url origin 2>/dev/null)
    if [ "$origin" = "$REPOSITORY_URL" ]; then
      [[ $VERBOSE -eq 1 ]] && echo "Dotfiles repository origin matches expected URL" || true;
      return 0
    else
      [[ $VERBOSE -eq 1 ]] && echo "Dotfiles repository origin ($origin) does not match expected URL ($REPOSITORY_URL)." || true;
      return 1
    fi
  else
    return 1
  fi
}

can_fix() { command -v git >/dev/null 2>&1; }

fix() {
  mkdir -p "$DOTFILES_PATH"
  git clone --depth=1 "$REPOSITORY_URL" "$DOTFILES_PATH"
}