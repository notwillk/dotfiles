# shellcheck disable=SC2034,SC2148

ID="git-aliases"
DESCRIPTION="Ensure that useful git aliases are set up"

declare -gA GIT_ALIASES
GIT_ALIASES["git"]="!git"
GIT_ALIASES["st"]="status --short --branch"
GIT_ALIASES["cm"]="commit -m"
GIT_ALIASES["br"]="branch"
GIT_ALIASES["co"]="checkout"
GIT_ALIASES["cp"]="cherry-pick"
GIT_ALIASES["dc"]="diff --cached"
GIT_ALIASES["lol"]="log --graph --decorate --pretty=oneline --abbrev-commit"
GIT_ALIASES["sha"]="rev-parse HEAD"
GIT_ALIASES["log"]="log --decorate"
GIT_ALIASES["head"]="log --stat --decorate -1 HEAD"
GIT_ALIASES["undo"]="reset --soft HEAD^"
GIT_ALIASES["aliases"]="!git config --get-regexp ^alias | cut -c 7-"
GIT_ALIASES["recent"]="!git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname)' | cut -c 12- | head"
GIT_ALIASES["wip"]="!sh -c 'git commit -m \"WIP: \$(date \"+%Y-%m-%d %H:%M:%S\")\"'"
GIT_ALIASES["unwip"]="!f(){ msg=\$(git log -1 --pretty=%B) && echo \"\$msg\" | grep -Eq '^WIP(:|$)' && git reset --soft HEAD^ && f || true; }; f"

check() {
  local VERBOSE="${1:-0}"
  local failed=0
  [[ "$VERBOSE" == "1" ]] && echo "🔍 Checking git aliases..."

  for alias in "${!GIT_ALIASES[@]}"; do
    local expected="${GIT_ALIASES[$alias]}"
    local actual
    actual="$(git config --get "alias.$alias" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
      failed=1
      [[ "$VERBOSE" == "1" ]] && echo "➕ Missing/incorrect: $alias (exp: '$expected', got: '${actual:-<unset>}')"
    else
      [[ "$VERBOSE" == "1" ]] && echo "✅ $alias -> '$expected'"
    fi
  done
  return $failed
}

can_fix() { command -v git >/dev/null 2>&1; }

fix() {
  local VERBOSE="${1:-0}"
  [[ "$VERBOSE" == "1" ]] && echo "🛠️ Setting git aliases…"

  for alias in "${!GIT_ALIASES[@]}"; do
    local expected="${GIT_ALIASES[$alias]}"
    local actual
    actual="$(git config --get "alias.$alias" 2>/dev/null || true)"
    if [[ "$actual" != "$expected" ]]; then
      git config --global "alias.$alias" "$expected"
      [[ "$VERBOSE" == "1" ]] && echo "✨ set: $alias -> '$expected'"
    else
      [[ "$VERBOSE" == "1" ]] && echo "✅ $alias -> '$expected'"
    fi
  done
}