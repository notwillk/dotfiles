ID="template"
DESCRIPTION="Not a real rule - copy this to create a new one"

# Optional: return 1 if the rule does not apply in this environment, 0 otherwise
applies() { return 1; }

# return 0 if the check passes, 1 otherwise
check() {
  if [ -d "$DOTFILES_PATH/.git" ]; then
    local origin
    origin=$(git -C "$DOTFILES_PATH" remote get-url origin 2>/dev/null)
    [ "$origin" = "$REPOSITORY_URL" ]
  else
    return 1
  fi
}

# Optional: return 0 if the rule can be auto-fixed, 1 otherwise
can_fix() { return 1; }

# attempt to fix the issue; return 0 on success, 1 otherwise
fix() {
  mkdir -p "$DOTFILES_PATH"
  git clone "$REPOSITORY_URL" "$DOTFILES_PATH"
}