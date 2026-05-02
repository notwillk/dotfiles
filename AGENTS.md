# AGENTS.md

Guidance for agents working in this dotfiles repo.

## Repo Purpose

This repository manages a user home directory with GNU Stow.

The Stow package is `home/`. Files under `home/` are intended to appear under
`$HOME` after install. For example:

- `home/managed_by_dofiles.md` maps to `$HOME/managed_by_dofiles.md`
- `home/.agents/skills/...` maps to `$HOME/.agents/skills/...`

Do not assume the target home directory is this repo or this dev container. The
scripts are designed to work against any valid `$HOME`.

## Lifecycle Scripts

Use the root scripts rather than hand-running Stow in normal work:

- `./install.sh`
- `./verify.sh`
- `./uninstall.sh`

`install.sh`:

- validates `$HOME`
- ensures GNU Stow is installed
- stows the `home` package into `$HOME`
- links `home/.codex/config.toml` into `$HOME/.codex/config.toml` explicitly

`verify.sh`:

- uses `stow --simulate` to check whether the `home` package is fully linked
- verifies `$HOME/.codex/config.toml` points at this repo
- exits nonzero if anything is missing, conflicting, or unmanaged

`uninstall.sh`:

- removes Stow-managed links from `$HOME`
- removes the Codex config link only when it points at this repo
- does not uninstall GNU Stow

## Stow Ignore Rules

Stow ignore rules live in:

```text
home/.stow-local-ignore
```

This file must stay inside the top-level Stow package directory. A repo-root
`.stow-local-ignore` will not apply to the `home` package.

The scripts intentionally do not pass `--ignore` flags. Prefer editing
`home/.stow-local-ignore` when Stow should skip package paths.

## Special Codex Config Handling

`home/.codex/config.toml` is not managed directly by Stow.

Reason: many environments already have `$HOME/.codex` as a real directory or an
absolute symlink. Stow can conflict with that and may print absolute-symlink bug
messages.

Instead:

- Stow ignores `.codex`
- `install.sh` creates `$HOME/.codex` if needed
- `install.sh` backs up an unmanaged existing `config.toml`
- `install.sh` symlinks `$HOME/.codex/config.toml` to this repo
- `verify.sh` checks that symlink
- `uninstall.sh` removes only that symlink

Do not replace this with plain Stow handling unless you also handle existing
`$HOME/.codex` directories and symlinks safely.

## Testing

The Docker test runner is:

```sh
tests/run.sh --all
```

Run it after changing any lifecycle script, Stow layout, install method, or
ignore rule.

You can run one case with:

```sh
tests/run.sh tests/00-devcontainers-ubuntu-stow-installed.Dockerfile
```

The tests mount this repo read-only and use a temporary `$HOME` inside the
container.

The expected normal lifecycle is:

1. `verify` fails before install
2. `install` passes
3. `verify` passes
4. `uninstall` passes
5. `verify` fails after uninstall

The test matrix also covers missing `$HOME`, missing Stow, missing package
manager, target conflicts, read-only homes, and package-manager detection.

## Safety Rules

- Do not run lifecycle scripts against the real `$HOME` unless that is the
  intended target.
- For local checks, prefer an overridden temp home:

  ```sh
  HOME="$PWD/tmp/test-home" ./install.sh
  HOME="$PWD/tmp/test-home" ./verify.sh
  HOME="$PWD/tmp/test-home" ./uninstall.sh
  ```

- Do not delete user files to resolve Stow conflicts.
- If an unmanaged target file exists, back it up or fail clearly.
- Do not uninstall GNU Stow in `uninstall.sh`.
- Do not add secrets, tokens, or machine-local credentials to `home/`.

## Commit Notes

Before committing lifecycle changes, run:

```sh
bash -n install.sh uninstall.sh verify.sh tests/run.sh
tests/run.sh --all
```

If Docker is unavailable, state that clearly in the final message.
