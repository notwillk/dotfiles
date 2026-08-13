# This Home Directory Is Managed By Dotfiles

This home is managed from a Git repository by dof. During the current
transition, dof runs GNU Stow to create the managed symlinks and retains a few
copied shell, Git, and SSH entrypoint files.

Repository: <https://github.com/notwillk/dotfiles>

## Where The Workspace Lives

The canonical checkout is:

```sh
$HOME/.dof/workspace
```

The dof executable is:

```sh
$HOME/.dof/bin/dof
```

Managed Stow links should point into `$HOME/.dof/workspace/home`.

## Update This Home Directory

```sh
git -C "$HOME/.dof/workspace" pull --ff-only
"$HOME/.dof/bin/dof" apply
"$HOME/.dof/workspace/verify.sh"
```

The default dof feature installs GNU Stow when needed, preserves backups under
`$HOME/.dotfiles/backups`, copies the initial entrypoint files, and refreshes
managed links. Reapplying is supported.

## Change A Managed File

Edit the source under `$HOME/.dof/workspace`, then run `dof apply`, verify,
commit, and push:

```sh
cd "$HOME/.dof/workspace"
"$HOME/.dof/bin/dof" apply
./verify.sh
git status
git add .
git commit -m "Update dotfiles"
git push
```

## Remove Managed Links

```sh
"$HOME/.dof/workspace/uninstall.sh"
```

This removes Stow-owned links and the Codex config link only when it points
into the active workspace. It intentionally leaves copied initial files,
backups, GNU Stow, the dof binary, and dof state in place.

If an apply reports a conflict, do not delete the target blindly. Determine
whether it is an unmanaged file, a link from an older checkout, or a managed
link before changing it.
