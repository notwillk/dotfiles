function psport() {
  if [ -z "${1:-}" ]; then
    printf 'usage: psport PORT\n' >&2
    return 2
  fi

  local pids
  pids="$(lsof -ti "TCP:$1" -sTCP:LISTEN)"

  if [ -z "$pids" ]; then
    printf 'No process is listening on port %s\n' "$1" >&2
    return 1
  fi

  ps -p "$(printf '%s\n' "$pids" | paste -sd, -)"
}

function killport() {
  if [ -z "${1:-}" ]; then
    printf 'usage: killport PORT\n' >&2
    return 2
  fi

  local pids
  pids="$(lsof -ti "TCP:$1" -sTCP:LISTEN | sort -u)"

  if [ -z "$pids" ]; then
    printf 'No process is listening on port %s\n' "$1" >&2
    return 1
  fi

  printf '%s\n' "$pids" | xargs kill -9
}
