# GNU Stow Reference

## Table of Contents

- Concepts
- Option Summary
- Tree Folding
- Deleting Packages
- Resource Files
- Known Pitfalls

## Concepts

GNU Stow manages farms of symbolic links. It lets separate package directories appear installed under one target tree.

- A package is a related collection of files and directories administered as a unit.
- A target directory is the root where package contents should appear installed.
- A stow directory contains separate package subdirectories.
- A package directory is one package's root inside the stow directory.
- An installation image is the package layout relative to the target directory.
- Stow creates relative symlinks only.

Default assumptions:

- The stow directory is `$STOW_DIR` if set, otherwise the current directory.
- The default target directory is the parent of the stow directory.
- Package arguments are directory names inside the stow directory.

## Option Summary

- `--simulate`, `--no`, `-n`: show what would happen without changing the filesystem.
- `--dir=DIR`, `-d DIR`: set the stow directory. Also changes the default target to `DIR`'s parent.
- `--target=DIR`, `-t DIR`: set the target directory.
- `--verbose[=N]`, `-v`: print more detail. Levels are 0-5. `--verbose=2` is useful for planning.
- `--stow`, `-S`: stow following packages. This is the default.
- `--delete`, `-D`: unstow following packages from the target tree.
- `--restow`, `-R`: unstow then stow. Useful after updating package contents.
- `--adopt`: when a target file already exists and is not Stow-owned, move it into the package directory, then stow it. This intentionally alters package contents.
- `--no-folding`: disable folding of newly stowed directories and refolding during unstow.
- `--ignore=REGEX`: ignore files ending in the Perl regex.
- `--defer=REGEX`: do not stow matching files if already stowed by another package.
- `--override=REGEX`: force stowing matching files if already stowed by another package.
- `--dotfiles`: map package entries beginning with `dot-` to target entries beginning with `.`.
- `--version`, `-V`: print version.
- `--help`, `-h`: print command syntax.

## Tree Folding

When possible, Stow creates one symlink to a whole package subtree instead of many per-file symlinks. This is called tree folding.

Example: if the target has no `bin`, stowing a package with `pkg/bin/...` may create target `bin -> stow/pkg/bin`.

When another package also needs `bin`, Stow can split open that folded tree: remove the folded symlink, create a real directory, and populate it with links into both packages. Stow first checks that the link points inside a valid package in the current stow directory.

Use `--no-folding` when a user wants explicit per-file/per-directory links and less folding/refolding behavior.

## Deleting Packages

`stow --delete pkg` removes target-tree links pointing into `pkg`. It does not remove the package directory or source files inside the stow directory.

During deletion, Stow scans the target tree, removes symlinks into the deleted package, removes directories that become empty, and may refold directories that now contain only links to a single remaining package.

## Resource Files

Stow reads default command-line options from:

1. `.stowrc` in the current directory
2. `~/.stowrc`

If both exist, their options are effectively appended. Command-line options override single-value resource options such as `--target` or `--dir`; multi-value options such as `--ignore` are appended.

Path options expand environment variables and `~`.

Resource-file package names and action options `-D`, `-R`, and `-S` are ignored.

Useful dotfiles `.stowrc` example:

```text
--target=~
--dotfiles
--ignore='(^|/)\.git($|/)'
```

## Known Pitfalls

- Empty package directories can be mishandled in some split/refold situations. Use a placeholder file such as `.placeholder` if an empty directory must persist.
- Multiple stow directories have edge cases around splitting folded symlinks that point into a different stow directory.
- `--adopt` changes the package tree. Use version control to inspect the moved files afterward.
- Conflicts usually mean a target path exists and is not owned by Stow. Resolve deliberately; do not delete blindly.
