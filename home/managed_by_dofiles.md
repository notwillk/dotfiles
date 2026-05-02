# This Home Directory Is Managed By Dotfiles

Some files in this home directory may be symlinks managed by a Git repository
and GNU Stow. If you found this file unexpectedly, it is here to explain where
those files come from and how to update or remove them safely.

Repository:

- SSH: `git@github.com:notwillk/dotfiles.git`
- Web: `https://github.com/notwillk/dotfiles`

## What GNU Stow Does

GNU Stow links files from a source repository into another directory. In this
setup, the `home/` package from the dotfiles repo is linked into `$HOME`.

That means this file usually lives at:

```sh
$HOME/managed_by_dofiles.md
```

but the real file is stored in the dotfiles repository at:

```sh
home/managed_by_dofiles.md
```

## Find The Dotfiles Repo

If this file is a symlink, `ls -l` will show where it points:

```sh
ls -l "$HOME/managed_by_dofiles.md"
```

The target should include a path ending in:

```sh
home/managed_by_dofiles.md
```

The dotfiles repo is the parent directory of that `home/` directory. Change into
that repo before running the commands below.

If the repo is missing, clone it again:

```sh
git clone git@github.com:notwillk/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## Update This Home Directory

From the dotfiles repo:

```sh
git pull
./install.sh
stow --restow --dir "$PWD" --target "$HOME" home
```

`install.sh` is idempotent. It is safe to run more than once. It ensures GNU
Stow is installed before setup continues. If Stow is already installed, it exits
successfully. If Stow cannot be installed, it fails so the update does not leave
the home directory partially configured.

`stow --restow` refreshes the symlinks from the repo into this home directory.

## Change A Managed File

Edit the real file in the dotfiles repo when possible, not the symlink in
`$HOME`.

After editing, run:

```sh
stow --restow --dir "$PWD" --target "$HOME" home
```

Then commit and push the change:

```sh
git status
git add .
git commit -m "Update dotfiles"
git push
```

Other machines can pick up the change by running the update commands above.

## Remove Managed Symlinks

From the dotfiles repo, run the uninstall lifecycle script when it exists:

```sh
./uninstall.sh
```

The expected teardown behavior is to remove the symlinks managed by Stow:

```sh
stow --delete --dir "$PWD" --target "$HOME" home
```

This should remove symlinks only. It should not delete the real files stored in
the dotfiles repo, and it should not uninstall GNU Stow unless that behavior is
explicitly added and documented.

## Useful Stow Commands

Preview changes without modifying files:

```sh
stow --no --verbose --dir "$PWD" --target "$HOME" home
```

Create or refresh symlinks:

```sh
stow --restow --dir "$PWD" --target "$HOME" home
```

Remove managed symlinks:

```sh
stow --delete --dir "$PWD" --target "$HOME" home
```

If Stow reports a conflict, a real file already exists where a symlink would be
created. Move that file aside, copy its contents into the repo, or decide
intentionally which version should win.
