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

      assert_regular_file() {
        local path="$1"

        if [[ ! -f "${path}" || -L "${path}" ]]; then
          echo "[container] expected regular file: ${path}" >&2
          exit 1
        fi
      }

      assert_symlink() {
        local path="$1"

        if [[ ! -L "${path}" ]]; then
          echo "[container] expected symlink: ${path}" >&2
          exit 1
        fi
      }

      assert_directory_not_symlink() {
        local path="$1"

        if [[ ! -d "${path}" || -L "${path}" ]]; then
          echo "[container] expected real directory: ${path}" >&2
          exit 1
        fi
      }

      assert_missing() {
        local path="$1"

        if [[ -e "${path}" || -L "${path}" ]]; then
          echo "[container] expected missing path: ${path}" >&2
          exit 1
        fi
      }

      assert_glob_exists() {
        local pattern="$1"

        if ! compgen -G "${pattern}" >/dev/null; then
          echo "[container] expected at least one match: ${pattern}" >&2
          exit 1
        fi
      }

      assert_installed_ownership() {
        assert_directory_not_symlink "${HOME}/.ssh"
        assert_directory_not_symlink "${HOME}/.ssh/config.d"

        assert_regular_file "${HOME}/.gitconfig"
        assert_regular_file "${HOME}/.ssh/config"
        assert_regular_file "${HOME}/.ssh/config.d/github"

        assert_symlink "${HOME}/.gitconfig.managed"
        assert_symlink "${HOME}/.ssh/config.d/00-defaults"
        assert_symlink "${HOME}/managed_by_dofiles.md"
      }

      assert_uninstalled_ownership() {
        assert_regular_file "${HOME}/.gitconfig"
        assert_regular_file "${HOME}/.ssh/config"
        assert_regular_file "${HOME}/.ssh/config.d/github"

        assert_missing "${HOME}/.gitconfig.managed"
        assert_missing "${HOME}/.ssh/config.d/00-defaults"
        assert_missing "${HOME}/managed_by_dofiles.md"
      }

      run_dotfile_tests() {
        local dot_home
        dot_home="/tmp/dotfile-unit-home"

        rm -rf "${dot_home}"
        mkdir -p "${dot_home}"
        cp -R ./initial-files/. "${dot_home}/"

        mkdir -p "${dot_home}/.config/shell"
        ln -s /workspace/dotfiles/home/.config/shell/common.d "${dot_home}/.config/shell/common.d"
        ln -s /workspace/dotfiles/home/.config/shell/bash.d "${dot_home}/.config/shell/bash.d"
        ln -s /workspace/dotfiles/home/.config/shell/zsh.d "${dot_home}/.config/shell/zsh.d"

        expect_pass "dotfiles: bash startup syntax" bash -n "${dot_home}/.bashrc"
        expect_pass "dotfiles: bash snippets syntax" \
          bash -lc "find home/.config/shell/common.d home/.config/shell/bash.d -type f -print0 | xargs -0 bash -n"
        expect_pass "dotfiles: bash startup loads" \
          env HOME="${dot_home}" bash --rcfile "${dot_home}/.bashrc" -i -c "type psport >/dev/null && type killport >/dev/null"

        if command -v zsh >/dev/null 2>&1; then
          expect_pass "dotfiles: zsh startup syntax" zsh -n "${dot_home}/.zshrc"
          expect_pass "dotfiles: zsh snippets syntax" \
            zsh -c "find home/.config/shell/common.d home/.config/shell/zsh.d -type f -print0 | xargs -0 zsh -n"
          expect_pass "dotfiles: zsh startup loads" \
            env HOME="${dot_home}" zsh -i -c "source \"${dot_home}/.zshrc\"; whence psport >/dev/null; whence killport >/dev/null"
        else
          echo "[container] skipping zsh dotfile checks because zsh is unavailable"
        fi

        if command -v git >/dev/null 2>&1; then
          expect_pass "dotfiles: managed gitconfig parses" \
            bash -lc "git config --file home/.gitconfig.managed --list >/dev/null"
          expect_pass "dotfiles: initial gitconfig include parses" \
            bash -lc "[ \"\$(git config --file initial-files/.gitconfig --get include.path)\" = \"~/.gitconfig.managed\" ]"
        else
          echo "[container] skipping git config checks because git is unavailable"
        fi

        if command -v ssh >/dev/null 2>&1; then
          mkdir -p "${dot_home}/.ssh/config.d"
          ln -s /workspace/dotfiles/home/.ssh/config.d/00-defaults "${dot_home}/.ssh/config.d/00-defaults"
          ln -s /workspace/dotfiles/home/.ssh/known_hosts_github "${dot_home}/.ssh/known_hosts_github"
          expect_pass "dotfiles: ssh config parses" \
            bash -lc "env HOME=\"${dot_home}\" ssh -F \"${dot_home}/.ssh/config\" -G github.com >/dev/null"
          expect_pass "dotfiles: ssh github known-hosts config applies" \
            bash -lc "env HOME=\"${dot_home}\" ssh -F \"${dot_home}/.ssh/config\" -G github.com | grep -F \"userknownhostsfile \" | grep -F \".ssh/known_hosts_github\" >/dev/null"
        else
          echo "[container] skipping ssh config checks because ssh is unavailable"
        fi
      }

      run_normal_lifecycle() {
        expect_pass "syntax: install.sh" bash -n ./install.sh
        expect_pass "syntax: uninstall.sh" bash -n ./uninstall.sh
        expect_pass "syntax: verify.sh" bash -n ./verify.sh
        run_dotfile_tests

        expect_fail "install with HOME unset" env -u HOME ./install.sh
        expect_fail "verify with HOME unset" env -u HOME ./verify.sh
        expect_fail "uninstall with HOME unset" env -u HOME ./uninstall.sh

        expect_fail "install with missing HOME" env HOME=/tmp/does-not-exist ./install.sh
        expect_fail "verify with missing HOME" env HOME=/tmp/does-not-exist ./verify.sh
        expect_fail "uninstall with missing HOME" env HOME=/tmp/does-not-exist ./uninstall.sh

        mkdir -p /tmp/conflict-home
        printf "not managed by stow\n" > /tmp/conflict-home/managed_by_dofiles.md
        expect_fail "install with existing target conflict" env HOME=/tmp/conflict-home ./install.sh

        mkdir -p /tmp/initial-file-directory-conflict/.ssh/config
        expect_fail \
          "install with initial file directory conflict" \
          env HOME=/tmp/initial-file-directory-conflict ./install.sh

        mkdir -p /tmp/codex-backup-home/.codex
        printf "local codex config\n" > /tmp/codex-backup-home/.codex/config.toml
        expect_pass \
          "install backs up existing Codex config under dotfiles backups" \
          env HOME=/tmp/codex-backup-home ./install.sh
        assert_glob_exists "/tmp/codex-backup-home/.dotfiles/backups/.codex/config.toml.backup.*"

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
        assert_installed_ownership
        expect_pass "verify after install" ./verify.sh
        expect_pass "second install backs up copied initial files" ./install.sh
        assert_glob_exists "${HOME}/.dotfiles/backups/.gitconfig.backup.*"
        assert_glob_exists "${HOME}/.dotfiles/backups/.ssh/config.backup.*"
        assert_installed_ownership
        expect_pass "uninstall" ./uninstall.sh
        assert_uninstalled_ownership
        expect_fail "verify after uninstall" ./verify.sh
      }

      run_no_package_manager_case() {
        expect_pass "syntax: install.sh" bash -n ./install.sh
        expect_pass "syntax: uninstall.sh" bash -n ./uninstall.sh
        expect_pass "syntax: verify.sh" bash -n ./verify.sh
        run_dotfile_tests

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
