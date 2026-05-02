# ensure dirs exist
mkdir -p "$HOME/.config/shell/common.d"
mkdir -p "$HOME/.config/shell/bash.d"
mkdir -p "$HOME/.config/bash/completions.d"

# load shared
for f in "$HOME"/.config/shell/common.d/*.sh; do
  [ -r "$f" ] && . "$f"
done

# load bash-specific
for f in "$HOME"/.config/shell/bash.d/*.bash; do
  [ -r "$f" ] && . "$f"
done

# load completions
for f in "$HOME"/.config/bash/completions.d/*.bash; do
  [ -r "$f" ] && . "$f"
done
