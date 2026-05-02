__dev_prompt_bash() {
  local green="\[\033[0;32m\]"
  local red="\[\033[1;31m\]"
  local cyan="\[\033[0;36m\]"
  local branch_red="\[\033[1;31m\]"
  local lightblue="\[\033[1;34m\]"
  local reset="\[\033[0m\]"
  local userpart

  if [ -n "${GITHUB_USER:-}" ]; then
    userpart="${green}@${GITHUB_USER}"
  else
    userpart="${green}\u"
  fi

  PS1="${userpart} "'$(if [ "$?" -ne 0 ]; then printf "\[\033[1;31m\]➜"; else printf "\[\033[0m\]➜"; fi)'" ${lightblue}\w ${cyan}"'$(branch="$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)"; if [ -n "${branch:-}" ]; then printf "(\[\033[1;31m\]%s\[\033[0;36m\]) " "$branch"; fi)'"${reset}\$ "
}

__dev_prompt_bash
export PROMPT_DIRTRIM=4
