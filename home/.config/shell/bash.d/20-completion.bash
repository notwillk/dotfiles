if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

for f in "$HOME"/.config/bash/completions.d/*.bash; do
  [ -r "$f" ] && . "$f"
done
