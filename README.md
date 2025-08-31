# dotfiles

A way of installing my preferred setup for a posix environment

## Installation

Run `./install.sh`

## Homelint

Homelint is a simple CLI tool to lint, check, and fix your home environment setup using modular "rule" scripts.

### Usage

```bash
homelint [--verbose] [--rules <glob>] <command> [<rule-id>]
```

#### Commands

- `list [<rule-id>]`  
  List all available rules (or just one if `<rule-id>` is specified).

- `check [<rule-id>]`  
  Run the `check()` function from rules. Exits with nonzero if any fail.  
  Example:
  ```bash
  homelint check
  homelint check homelint-in-path
  ```

- `fix [<rule-id>]`  
  Run `check()`, and if it fails, attempt to run `fix()` (if present).  
  Example:
  ```bash
  homelint fix
  homelint fix dotfiles-cloned
  ```

- `update`  
  Pull the latest changes for your dotfiles repo.  
  Example:
  ```bash
  homelint update
  ```

#### Options

- `--verbose, -v`  
  Print extra logging during execution.
- `--rules <glob>`  
  Override the glob for rule files. Defaults to `rules.d/*.rule.sh`.

---

### Rule Format

Each rule is a small Bash script ending in `.rule.sh` that defines a set of functions/variables.

#### Required

- `ID` — short unique string identifier for the rule.
- `DESCRIPTION` — one-line description of what the rule enforces.
- `check()` — function that returns 0 if the rule is satisfied, nonzero otherwise.

#### Optional

- `applies()` — return nonzero to skip this rule (e.g. only apply on certain shells).
- `can_fix()` — return 0 if `fix()` can be safely run, nonzero otherwise.
- `fix()` — attempt to remediate the issue.

All functions receive a single argument: the `VERBOSE` flag (0 or 1).

#### Example Rule

```bash
# rules.d/001-homelint-in-path.rule.sh
ID="homelint-in-path"
DESCRIPTION="Ensure 'homelint' is installed and on PATH"

check() {
  command -v homelint >/dev/null 2>&1
}

fix() {
  mkdir -p "$HOME/.bin"
  cp ./homelint "$HOME/.bin/"
  # detect shell type and update config file accordingly
  if [ -n "$BASH_VERSION" ]; then
    echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.bashrc"
  elif [ -n "$ZSH_VERSION" ]; then
    echo 'export PATH="$HOME/.bin:$PATH"' >> "$HOME/.zshrc"
  elif [ -n "$FISH_VERSION" ]; then
    echo 'set -x PATH $HOME/.bin $PATH' >> "$HOME/.config/fish/config.fish"
  fi
}
```

---

### Example Workflow

```bash
# See all rules
homelint list

# Check all rules
homelint check

# Fix problems
homelint fix

# Check/fix a specific rule
homelint check homelint-in-path
homelint fix homelint-in-path

# Update your dotfiles repo
homelint update
```
