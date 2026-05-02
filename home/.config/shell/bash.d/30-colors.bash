if [ -x /usr/bin/dircolors ]; then
  if [ -r "$HOME/.dircolors" ]; then
    eval "$(dircolors -b "$HOME/.dircolors")"
  else
    eval "$(dircolors -b)"
  fi

  alias ls="ls --color=auto"
  alias grep="grep --color=auto"
fi

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
