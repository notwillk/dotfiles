---
name: gnu-stow
description: Manage GNU Stow symlink farms, package trees, dotfile repositories, and stow/unstow/restow workflows. Use when Codex needs to explain or run stow commands, design a stow directory layout, migrate files into a Stow-managed package, troubleshoot Stow conflicts, use .stowrc, handle dotfiles with dot- prefixes, or reason about target directories, package directories, tree folding, and relative symlinks.
---

# GNU Stow

Use this skill to help with GNU Stow, especially for dotfiles and symlink-farm package management. Prefer safe, inspectable workflows: identify the stow directory and target directory, simulate first, then apply changes only when the user has asked for mutation.

## Core Model

Keep these terms straight before suggesting commands:

- **Stow directory**: directory containing package subdirectories. Defaults to `$STOW_DIR` or the current directory.
- **Package**: a subdirectory inside the stow directory, named on the command line.
- **Package directory**: the package's root inside the stow directory.
- **Installation image**: the package contents laid out as they should appear under the target directory.
- **Target directory**: tree where package contents appear as symlinks. Defaults to the parent of the stow directory.

Stow creates relative symlinks in the target tree pointing back into package directories. It owns target-tree links that point into packages in the current stow directory; it should not delete files it does not own.

## Default Workflow

1. Discover or confirm the layout:
   - Current directory
   - Intended stow directory
   - Intended target directory
   - Package names
   - Whether this is stow, delete, restow, or adopt

2. Inspect before changing:
   - Use `find`, `ls -la`, or `tree` when useful.
   - Use `stow --simulate --verbose=2 ...` before any real stow, delete, restow, or adopt operation.
   - Explain conflicts rather than forcing through them.

3. Run the minimal command:
   - Prefer explicit `--dir` and `--target` when the working directory is ambiguous.
   - Use `--dotfiles` for packages that intentionally store `.foo` as `dot-foo`.
   - Use `--restow` after package contents change and obsolete links may need pruning.

4. Verify after mutation:
   - Check the target paths and symlink destinations.
   - For dotfiles, verify representative links such as `~/.bashrc`, `~/.config/...`, or the exact files requested.

## Common Commands

From the stow directory, stow package `pkg` into the parent directory:

```bash
stow --simulate --verbose=2 pkg
stow pkg
```

Stow from an explicit dotfiles repo into `$HOME`:

```bash
stow --simulate --verbose=2 --dir "$HOME/dotfiles" --target "$HOME" zsh
stow --dir "$HOME/dotfiles" --target "$HOME" zsh
```

Use `dot-` names for dotfiles:

```bash
stow --simulate --verbose=2 --dotfiles --dir "$HOME/dotfiles" --target "$HOME" shell
stow --dotfiles --dir "$HOME/dotfiles" --target "$HOME" shell
```

Unstow a package without removing the package directory:

```bash
stow --simulate --verbose=2 --delete --dir "$HOME/dotfiles" --target "$HOME" shell
stow --delete --dir "$HOME/dotfiles" --target "$HOME" shell
```

Restow after renaming, deleting, or moving package files:

```bash
stow --simulate --verbose=2 --restow --dir "$HOME/dotfiles" --target "$HOME" shell
stow --restow --dir "$HOME/dotfiles" --target "$HOME" shell
```

## Safety Rules

- Treat `--adopt` as high risk: it moves existing target files into the package directory. Require a clean VCS state or backup recommendation before using it.
- Never recommend manual deletion of target files until it is clear whether they are Stow-owned symlinks, user files, or directories with mixed contents.
- Do not assume the target is `$HOME`; for software package layouts it may be `/usr/local`, another prefix, or a test directory.
- Do not treat deleting a package with `--delete` as deleting files from the stow directory. It only removes Stow-owned target-tree links/directories.
- For conflicts, preserve the non-owned file and present choices: move it into the package, rename it, use `--adopt` with care, or exclude/defer/override with a regex when appropriate.

## Dotfiles Guidance

For dotfile repositories, recommend a layout like:

```text
~/dotfiles/
  shell/
    dot-zshrc
    dot-config/
      starship.toml
  git/
    dot-gitconfig
```

Then stow with:

```bash
stow --dotfiles --dir "$HOME/dotfiles" --target "$HOME" shell git
```

Without `--dotfiles`, files named `dot-zshrc` remain `dot-zshrc` in the target. With `--dotfiles`, Stow maps the `dot-` prefix to `.`.

## When More Detail Is Needed

Read `references/stow-reference.md` for option behavior, tree folding, `.stowrc`, conflicts, and known pitfalls from the Stow manual.
