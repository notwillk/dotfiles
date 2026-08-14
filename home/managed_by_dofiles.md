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

The default dof feature installs `$HOME/bin/rulesy` when needed. Rulesy then
installs GPG and GNU Stow, verifies the complete home package, and refreshes
managed links through the shared lifecycle helper. The feature preserves
backups under `$HOME/.dotfiles/backups`, copies the initial entrypoint files,
and manages the separate Codex config link. Reapplying is supported.

On macOS, the `macos-gui` feature uses Rulesy to install Homebrew, append its
desired formula, casks, and App Store entries to `$HOME/.Brewfile`, and
reconcile them through `brew bundle --global`.

On macOS 10.14 and newer, it also ensures `$HOME/Screenshots` exists and is
configured as the screenshot save location. The upper Hot Corners disable the
screen saver; Command plus either lower corner locks the screen. The
accessibility rules enable Control-scroll screen zoom. These rules skip on
other systems.

The Lock Screen rules turn the display off after 10 minutes of inactivity on
battery and after 60 minutes on a power adapter.

The Trackpad rules disable swiping between pages and the two-finger swipe from
the right edge that opens Notification Center.

The appearance rules keep macOS in Dark mode. On macOS 26 and newer, they use
the Clear icon and widget style; the Clear light/dark variant follows the
system appearance.

The menu bar rules keep the clock digital and always show the date while
hiding the weekday, AM/PM label, seconds, separator flashing, and time
announcements.
On macOS 26 and newer, Wi-Fi, battery, and weather remain visible; Focus,
Screen Mirroring, Display, Sound, and Timer appear only while active; and
Spotlight, Bluetooth, AirDrop, Fast User Switching, Text Input, Time Machine,
Keyboard Brightness, and VPN remain hidden.

On Apple silicon Macs, the `hostname` feature derives a name from the machine
family, chip tier, and model year, such as `mbp-m4p-2024`. If the computer,
Bonjour, or network hostname differs, `dof apply` requests administrator
authentication before reconciling all three.

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
backups, GNU Stow, Rulesy, the dof binary, and dof state in place.

If an apply reports a conflict, do not delete the target blindly. Determine
whether it is an unmanaged file, a link from an older checkout, or a managed
link before changing it.
