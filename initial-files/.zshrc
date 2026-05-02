# ensure dirs exist
mkdir -p ~/.config/shell/common.d
mkdir -p ~/.config/shell/zsh.d
mkdir -p ~/.config/zsh/completions.d

# load shared
for f in ~/.config/shell/common.d/*.sh(N); do
  source "$f"
done

# load zsh-specific
for f in ~/.config/shell/zsh.d/*.zsh(N); do
  source "$f"
done

# completions (makes dir "meaningful")
fpath=(~/.config/zsh/completions.d $fpath)
autoload -Uz compinit
compinit
