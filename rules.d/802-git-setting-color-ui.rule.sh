SECTION="color"
VAR="ui"
VALUE="true"

PARAM="$SECTION.$VAR"
ID="git-setting-$SECTION-$VAR"
DESCRIPTION="Ensure that git $PARAM setting is set up"

check() {
  local VERBOSE="${1:-0}"
  local setting
  setting="$(git config --global --get $PARAM 2>/dev/null || true)"
  if [[ "$setting" == "$VALUE" ]]; then
    [[ "$VERBOSE" == "1" ]] && echo "✅ git $PARAM is set to $VALUE"
    return 0
  else
    [[ "$VERBOSE" == "1" ]] && echo "❌ git $PARAM is not set to $VALUE (current: '$setting')"
    return 1
  fi
}

can_fix() { command -v git >/dev/null 2>&1; }

fix() {
  local VERBOSE="${1:-0}"
  local setting
  setting="$(git config --global --get $PARAM 2>/dev/null || true)"
  if [[ "$setting" == "$VALUE" ]]; then
    [[ "$VERBOSE" == "1" ]] && echo "✅ git $PARAM is set to $VALUE"
    return 0
  else
    git config --global "$PARAM" "$VALUE"
  fi
}