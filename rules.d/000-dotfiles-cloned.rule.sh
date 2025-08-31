ID="dotfiles-cloned"
DESCRIPTION="Ensure dotfiles is cloned"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
REPOSITORY_URL="https://github.com/notwillk/dotfiles.git"

check() {
  if [ -d "$DOTFILES_PATH/.git" ]; then
    local origin
    origin=$(git -C "$DOTFILES_PATH" remote get-url origin 2>/dev/null)
    [ "$origin" = "$REPOSITORY_URL" ]
  else
    return 1
  fi
}

can_fix() { command -v git >/dev/null 2>&1; }

fix() {
  mkdir -p "$DOTFILES_PATH"
  git clone "$REPOSITORY_URL" "$DOTFILES_PATH"
}