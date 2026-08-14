# AGENTS.md

Guidance for agents working in this dotfiles repo.

## Architecture

Dof owns bootstrap, workspace selection, and feature execution. Intentional
dof declarations live in `features/default/`, `features/hostname/`, and
`features/macos-gui/`.

This is a transitional architecture: `features/default/apply` installs
Rulesy when needed, exposes it through `dof run`, copies `initial-files/`,
and manages the special Codex link. Its Rulesy configuration installs GPG and
GNU Stow through the first available supported package manager, then checks and
reconciles `home/` through the shared
`features/default/scripts/stow-home-files` helper. Do not convert payload
files to native dof ownership unless explicitly asked.

The canonical checkout is `$HOME/.dof/workspace`. Files under `home/` map to
the same relative path beneath `$HOME`; files under `initial-files/` are
copied as regular files.

## Lifecycle

- `./install.sh` bootstraps `$HOME/.dof/bin/dof`, clones this repository,
  explicitly disables `macos-gui` for a fresh dof state, and runs `dof apply`.
  Installer reruns preserve the existing feature selection; users opt in with
  `dof feature enable macos-gui`.
- `features/default/apply` is the idempotent feature hook and underlying
  installer. After installing Rulesy, it runs the default Rulesy configuration
  with fixes enabled before copying initial files or linking Codex config.
  Rulesy installs GPG and Stow, hands off recognized legacy Stow ownership, and
  reconciles the active home package. The GPG rules are post-bootstrap
  maintenance and cannot satisfy dof's own installer prerequisites.
- `features/hostname/apply` derives the hardware-based macOS hostname and runs
  its local Rulesy configuration through `dof run rulesy`.
- `features/macos-gui/apply` runs its local Rulesy configuration through
  `dof run rulesy`. Its app rules append exact entries to `$HOME/.Brewfile`,
  then reconcile it through Homebrew Bundle.
- `verify.sh` delegates home-package simulation to the shared helper and checks
  the special Codex config link.
- `uninstall.sh` delegates active-workspace unstowing to the shared helper and
  removes the exact managed Codex link.

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

The shared home-files helper may automatically hand off links from an older
checkout. It must only unstow a package identified by the installed marker
link and must never use `stow --adopt`, delete unmanaged files, accept an
arbitrary target path, or use `dof clone --force`.

## Workspace Rules

Dof only discovers features beneath `features/`. The intentional features are
`features/default/`, `features/hostname/`, and `features/macos-gui/`.
Repository-level infrastructure directories are inert.

Do not add secrets, tokens, or machine-local credentials to managed payloads.

## Testing

Run:

```sh
bash -n install.sh features/default/apply features/hostname/apply \
  features/default/scripts/stow-home-files features/hostname/desired-hostname \
  features/macos-gui/apply uninstall.sh verify.sh tests/run.sh \
  tests/support/fake-dof.sh
dof lint .
tests/run.sh --all
```

The Docker tests use isolated temporary homes and local repository snapshots;
they must never install into the real `$HOME`. They cover package-manager
selection, bootstrap delegation, dof apply, Stow ownership, legacy handoff,
backups, conflicts, Rulesy delegation, hostname derivation, macOS gating,
GPG and Stow package-manager selection, shared-helper verification, and
uninstall behavior.

If Docker is unavailable, state that clearly in the final message.
