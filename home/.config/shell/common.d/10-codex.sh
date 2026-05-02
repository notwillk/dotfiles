if command -v codex >/dev/null 2>&1; then
  CODEX_BIN="$(command -v codex)"

  codex() {
    if [ "$#" -eq 0 ]; then
      "$CODEX_BIN" resume --last
    else
      "$CODEX_BIN" "$@"
    fi
  }
fi
