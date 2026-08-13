# AGENTS.md

Guidance for agents working in this dotfiles repo.

## Architecture

Dof owns bootstrap, workspace selection, and feature execution. The only
intentional dof declaration is the executable `features/default/apply` hook.

This is a transitional architecture: `features/default/apply` installs GNU
Stow when needed, copies `initial-files/`, and Stows `home/` into the
target `$HOME`.
Do not convert payload files to native dof ownership unless explicitly asked.

The canonical checkout is `$HOME/.dof/workspace`. Files under `home/` map to
the same relative path beneath `$HOME`; files under `initial-files/` are
copied as regular files.

## Lifecycle

- `./install.sh` bootstraps `$HOME/.dof/bin/dof`, clones this repository, and
  runs `dof apply`.
- `features/default/apply` is the idempotent feature hook and underlying
  installer.
- `verify.sh` simulates Stow and checks the special Codex config link.
- `uninstall.sh` removes Stow-owned links and the exact managed Codex link.

Normal maintenance is:

```sh
git -C "$HOME/.dof/workspace" pull --ff-only
"$HOME/.dof/bin/dof" apply
```

Uninstall deliberately leaves initial files, backups, GNU Stow,
`$HOME/.dof/bin/dof`, and the dof workspace/config in place.

## Stow and Codex Rules

Stow ignore rules remain in `home/.stow-local-ignore`. Do not move them to the
repository root or replace them with command-line ignore flags.

`home/.codex/config.toml` remains outside Stow because `$HOME/.codex` may be
a real directory or a directory symlink. The apply hook backs up an unmanaged
leaf and creates the exact config symlink. Uninstall removes it only when it
points into the active workspace.

The apply hook may automatically hand off links from an older checkout. It must
only unstow a package identified by the installed marker link and must never
use `stow --adopt`, delete unmanaged files, or use `dof clone --force`.

## Workspace Rules

Dof only discovers features beneath `features/`. For this migration, only
`features/default/` may contain dof declarations (`home/`, `snippets.yaml`, or
an `apply` hook). Repository-level infrastructure directories are inert.

Do not add secrets, tokens, or machine-local credentials to managed payloads.

## Testing

Run:

```sh
bash -n install.sh features/default/apply uninstall.sh verify.sh tests/run.sh
dof lint .
tests/run.sh --all
```

The Docker tests use isolated temporary homes and local repository snapshots;
they must never install into the real `$HOME`. They cover package-manager
selection, bootstrap delegation, dof apply, Stow ownership, legacy handoff,
backups, conflicts, verification, and uninstall behavior.

If Docker is unavailable, state that clearly in the final message.
