ID="github-ssh-hosts"
DESCRIPTION="Ensure that the default GitHub SSH hosts exist in known hosts"

GITHUB_KNOWN_HOSTS=$(cat <<'EOF'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
EOF
)

check() {
  VERBOSE="$1"

  # Search configured known_hosts files (supports hashed entries too)
  TMP_OUT="$(mktemp)"
  if ! ssh-keygen -F github.com >"$TMP_OUT" 2>/dev/null; then
    [ "$VERBOSE" = "1" ] && echo "No github.com entries found in known_hosts."
    rm -f "$TMP_OUT"
    return 1
  fi

  missing=0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! grep -Fqx "$line" "$TMP_OUT"; then
      missing=$((missing+1))
      [ "$VERBOSE" = "1" ] && echo "Missing key: $line"
    fi
  done <<EOF
$GITHUB_KNOWN_HOSTS
EOF

  rm -f "$TMP_OUT"
  if [ "$missing" -eq 0 ]; then
    [ "$VERBOSE" = "1" ] && echo "☑️  All GitHub host keys are present"
    return 0
  else
    [ "$VERBOSE" = "1" ] && echo "❌ $missing GitHub host key(s) missing"
    return 1
  fi
}

can_fix() {
  VERBOSE="$1"
  SSH_KEYGEN_BIN=$(command -v ssh-keygen || true)

  if [ "$VERBOSE" = "1" ]; then
    [ -n "$SSH_KEYGEN_BIN" ] && echo "☑️  ssh-keygen found" || echo "⚠️  ssh-keygen not found"
  fi

  if [ -n "$SSH_KEYGEN_BIN" ]; then
    return 0
  else
    return 1
  fi
}

fix() {
  VERBOSE="$1"

  # Ensure ~/.ssh exists with correct perms
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/known_hosts"
  chmod 600 "$HOME/.ssh/known_hosts"

  if [ "$VERBOSE" = "1" ]; then
    echo "💨 Removing existing github.com keys from known_hosts (if any)..."
  fi
  ssh-keygen -R github.com >/dev/null 2>&1 || true

  if [ "$VERBOSE" = "1" ]; then
    echo "➕ Adding GitHub SSH host keys to known_hosts..."
  fi

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if ! grep -Fqx "$line" "$HOME/.ssh/known_hosts"; then
      printf '%s\n' "$line" >> "$HOME/.ssh/known_hosts"
      [ "$VERBOSE" = "1" ] && echo "➕ Added: $(echo "$line" | awk '{print $2}')"
    else
      [ "$VERBOSE" = "1" ] && echo "👌 Already present: $(echo "$line" | awk '{print $2}')"
    fi
  done <<EOF
$GITHUB_KNOWN_HOSTS
EOF
}
