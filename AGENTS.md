# AGENTS.md

Guidance for agents working in this dotfiles repo.

## Architecture

Dof owns bootstrap, workspace selection, and feature execution. Intentional
dof declarations live in `features/default/`, `features/hostname/`, and
`features/macos-gui/`.

This is a transitional architecture: `features/default/apply` installs GNU
Stow and Rulesy when needed, exposes Rulesy through `dof run`, copies
`initial-files/`, and Stows `home/` into the target `$HOME`. Its Rulesy
configuration conditionally installs GPG through the first available supported
package manager before changing dotfile targets. Do not convert payload files
to native dof ownership unless explicitly asked.

The canonical checkout is `$HOME/.dof/workspace`. Files under `home/` map to
the same relative path beneath `$HOME`; files under `initial-files/` are
copied as regular files.

## Lifecycle

- `./install.sh` bootstraps `$HOME/.dof/bin/dof`, clones this repository, and
  runs `dof apply`.
- `features/default/apply` is the idempotent feature hook and underlying
  installer. After installing Rulesy, it runs
  `features/default/rulesy.yaml` with fixes enabled before copying or linking
  dotfiles. The GPG rules are post-bootstrap maintenance and cannot satisfy
  dof's own installer prerequisites.
- `features/hostname/apply` derives the hardware-based macOS hostname and runs
  its local Rulesy configuration through `dof run rulesy`.
- `features/macos-gui/apply` runs its local Rulesy configuration through
  `dof run rulesy`. Its app rules append exact entries to `$HOME/.Brewfile`,
  then reconcile it through Homebrew Bundle.
- `verify.sh` simulates Stow and checks the special Codex config link.
- `uninstall.sh` removes `home/` Stow-owned links and the exact managed Codex
  link.

Normal maintenance is:

```sh
git -C "$HOME/.dof/workspace" pull --ff-only
"$HOME/.dof/bin/dof" apply
```

Uninstall deliberately leaves initial files, backups, GNU Stow, Rulesy,
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

Dof only discovers features beneath `features/`. The intentional features are
`features/default/`, `features/hostname/`, and `features/macos-gui/`.
Repository-level infrastructure directories are inert.

Do not add secrets, tokens, or machine-local credentials to managed payloads.

## Testing

Run:

```sh
bash -n install.sh features/default/apply features/hostname/apply \
  features/hostname/desired-hostname features/macos-gui/apply uninstall.sh \
  verify.sh tests/run.sh tests/support/fake-dof.sh
dof lint .
tests/run.sh --all
```

The Docker tests use isolated temporary homes and local repository snapshots;
they must never install into the real `$HOME`. They cover package-manager
selection, bootstrap delegation, dof apply, Stow ownership, legacy handoff,
backups, conflicts, Rulesy delegation, hostname derivation, macOS gating,
GPG package-manager selection, verification, and uninstall behavior.

If Docker is unavailable, state that clearly in the final message.
