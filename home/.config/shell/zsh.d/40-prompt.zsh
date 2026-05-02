autoload -Uz vcs_info

precmd() {
  vcs_info
}

zstyle ":vcs_info:*" enable git
zstyle ":vcs_info:git:*" formats "(%F{red}%b%f) "

__dev_prompt_zsh() {
  local userpart

  if [[ -n "${GITHUB_USER:-}" ]]; then
    userpart="%F{green}@${GITHUB_USER} %f"
  else
    userpart="%F{green}%n %f"
  fi

  PROMPT='${userpart}%(?..%F{red})➜%f %F{blue}%4~%f ${vcs_info_msg_0_}%# '
}

__dev_prompt_zsh
