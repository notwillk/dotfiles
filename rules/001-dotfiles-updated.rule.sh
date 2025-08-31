# shellcheck disable=SC2034,SC2148

ID="dotfiles-updated"
DESCRIPTION="Ensure dotfiles is updated"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_PATH="${DOTFILES_PATH:-$HOME/.dotfiles}"
REPOSITORY_URL="https://github.com/notwillk/dotfiles.git"

check() {
  LOCAL_COMMIT=$(git -C "$DOTFILES_PATH" rev-parse @ 2>/dev/null)
  REMOTE_COMMIT=$(git -C "$DOTFILES_PATH" ls-remote origin HEAD | awk '{print $1}')

  if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    return 1
  fi

  return 0
}

can_fix() { return 0; }

fix() { git -C "$DOTFILES_PATH" pull --ff-only; }
