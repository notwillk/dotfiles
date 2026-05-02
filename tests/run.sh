#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<EOF
Usage:
  tests/run.sh --all
  tests/run.sh tests/<name>.Dockerfile
  tests/run.sh <name>.Dockerfile

Runs the dotfiles lifecycle in Docker with this repo mounted read-only.
EOF
}

die() {
  echo "[tests/run.sh] $*" >&2
  exit 1
}

dockerfiles_for_all() {
  find "${SCRIPT_DIR}" -maxdepth 1 -type f -name '*.Dockerfile' -print | sort
}

resolve_dockerfile() {
  local input="$1"

  if [[ -f "${input}" ]]; then
    cd "$(dirname "${input}")" && printf '%s/%s\n' "$(pwd)" "$(basename "${input}")"
    return
  fi

  if [[ -f "${SCRIPT_DIR}/${input}" ]]; then
    printf '%s/%s\n' "${SCRIPT_DIR}" "${input}"
    return
  fi

  die "Dockerfile not found: ${input}"
}

image_tag_for() {
  local dockerfile="$1"
  local name

  name="$(basename "${dockerfile}" .Dockerfile)"
  name="${name//[^a-zA-Z0-9_.-]/-}"
  printf 'dotfiles-test:%s\n' "${name}"
}

run_case() {
  local dockerfile="$1"
  local tag
  local case_name

  tag="$(image_tag_for "${dockerfile}")"
  case_name="$(basename "${dockerfile}" .Dockerfile)"

  echo "[tests/run.sh] Building ${tag} from ${dockerfile}"
  docker build --file "${dockerfile}" --tag "${tag}" "${REPO_ROOT}"

  echo "[tests/run.sh] Running ${tag}"
  docker run --rm \
    --env HOME=/tmp/test-home \
    --mount "type=bind,src=${REPO_ROOT},dst=/workspace/dotfiles,readonly" \
    --workdir /workspace/dotfiles \
    --tmpfs /tmp:rw,nosuid,nodev,mode=1777 \
    --env TEST_CASE_NAME="${case_name}" \
    "${tag}" \
    bash -lc '
      set -euo pipefail

      mkdir -p "${HOME}"

      expect_pass() {
        local label="$1"; shift

        echo "[container] expecting pass: ${label}"
        "$@"
      }

      expect_fail() {
        local label="$1"; shift
        local status

        echo "[container] expecting fail: ${label}"
        set +e
        "$@"
        status="$?"
        set -e

        if [[ "${status}" -eq 0 ]]; then
          echo "[container] expected failure but command passed: ${label}" >&2
          exit 1
        fi

        echo "[container] observed expected failure (${status}): ${label}"
      }

      run_normal_lifecycle() {
        expect_pass "syntax: install.sh" bash -n ./install.sh
        expect_pass "syntax: uninstall.sh" bash -n ./uninstall.sh
        expect_pass "syntax: verify.sh" bash -n ./verify.sh

        expect_fail "install with HOME unset" env -u HOME ./install.sh
        expect_fail "verify with HOME unset" env -u HOME ./verify.sh
        expect_fail "uninstall with HOME unset" env -u HOME ./uninstall.sh

        expect_fail "install with missing HOME" env HOME=/tmp/does-not-exist ./install.sh
        expect_fail "verify with missing HOME" env HOME=/tmp/does-not-exist ./verify.sh
        expect_fail "uninstall with missing HOME" env HOME=/tmp/does-not-exist ./uninstall.sh

        mkdir -p /tmp/conflict-home
        printf "not managed by stow\n" > /tmp/conflict-home/managed_by_dofiles.md
        expect_fail "install with existing target conflict" env HOME=/tmp/conflict-home ./install.sh

        mkdir -p /tmp/dotfiles-without-home
        cp ./install.sh ./verify.sh ./uninstall.sh /tmp/dotfiles-without-home/
        expect_fail "install with missing home package" env HOME=/tmp/test-home bash /tmp/dotfiles-without-home/install.sh
        expect_fail "verify with missing home package" env HOME=/tmp/test-home bash /tmp/dotfiles-without-home/verify.sh
        expect_fail "uninstall with missing home package" env HOME=/tmp/test-home bash /tmp/dotfiles-without-home/uninstall.sh

        if command -v su >/dev/null 2>&1; then
          mkdir -p /tmp/readonly-home
          chmod 0555 /tmp/readonly-home
          expect_fail \
            "install with read-only HOME" \
            su -s /bin/bash nobody -c "HOME=/tmp/readonly-home /workspace/dotfiles/install.sh"
          chmod 0755 /tmp/readonly-home
        else
          echo "[container] skipping read-only HOME check because su is unavailable"
        fi

        expect_fail "verify before install" ./verify.sh
        expect_pass "install" ./install.sh
        expect_pass "verify after install" ./verify.sh
        expect_pass "uninstall" ./uninstall.sh
        expect_fail "verify after uninstall" ./verify.sh
      }

      run_no_package_manager_case() {
        expect_pass "syntax: install.sh" bash -n ./install.sh
        expect_pass "syntax: uninstall.sh" bash -n ./uninstall.sh
        expect_pass "syntax: verify.sh" bash -n ./verify.sh

        expect_fail "verify before install" ./verify.sh
        expect_fail "install without stow or package manager" ./install.sh
        expect_fail "verify after failed install" ./verify.sh
        expect_fail "uninstall without stow" ./uninstall.sh
      }

      if [[ "${TEST_CASE_NAME}" == *"no-package-manager"* ]]; then
        run_no_package_manager_case
      else
        run_normal_lifecycle
      fi
    '

  echo "[tests/run.sh] Passed ${tag}"
}

if [[ "$#" -ne 1 ]]; then
  usage >&2
  exit 2
fi

if [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
  usage
  exit 0
fi

dockerfiles=()
if [[ "${1}" == "--all" ]]; then
  while IFS= read -r dockerfile; do
    dockerfiles+=("${dockerfile}")
  done < <(dockerfiles_for_all)

  if [[ "${#dockerfiles[@]}" -eq 0 ]]; then
    die "No Dockerfiles found in ${SCRIPT_DIR}"
  fi
else
  dockerfiles+=("$(resolve_dockerfile "${1}")")
fi

for dockerfile in "${dockerfiles[@]}"; do
  run_case "${dockerfile}"
done

echo "[tests/run.sh] All requested Docker tests passed."
