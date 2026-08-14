# Dotfiles

Personal dotfiles orchestrated by [dof](https://github.com/notwillk/dof).

A fresh installation explicitly enables only `default`. That feature installs
Rulesy and GPG, copies `initial-files/`, and manages the special Codex config
link. The optional `legacy` feature installs GNU Stow and reconciles the
existing `home/` payload through a shared Stow lifecycle helper. It is never
enabled by the bootstrap.

Install the default feature set with:

```sh
curl -fsSL https://raw.githubusercontent.com/notwillk/dotfiles/main/install.sh | bash
```

This fails on HTTP errors, follows redirects, hides the progress meter, and
still prints useful error messages.

To opt into the transitional Stow-managed home links:

```sh
"$HOME/.dof/bin/dof" feature enable legacy
"$HOME/.dof/bin/dof" apply
```

The `hostname` and `macos-gui` features are also disabled on a fresh install.
Enable either one explicitly with `dof feature enable <name>` before applying.

GPG and Stow use the first supported package manager already present on the
machine, with Homebrew preferred before the supported system managers. GPG is
post-bootstrap maintenance: dof's own installer must still be able to complete
before the default feature can run.

The `macos-gui` feature uses Rulesy to install Homebrew, append its desired
formula, casks, and App Store entries to `$HOME/.Brewfile`, and reconcile them
through `brew bundle --global`. It keeps macOS screenshot storage pointed at
`$HOME/Screenshots`. It also configures the upper Hot Corners to disable the
screen saver, Command plus either lower corner to lock the screen, and
Control-scroll to zoom the screen. Its rules skip on non-macOS systems;
screenshot and Hot Corner rules also skip macOS releases older than 10.14.
The Lock Screen rules turn the display off after 10 minutes of inactivity on
battery and after 60 minutes on a power adapter.
The Trackpad rules disable swiping between pages and the two-finger swipe from
the right edge that opens Notification Center.
The appearance rules keep the system in Dark mode and, on macOS 26 and newer,
use the Clear icon and widget style.
The menu bar clock always shows the date in digital style while hiding the
weekday, AM/PM label, seconds, separator flashing, and time announcements.
On macOS 26 and newer, Wi-Fi, battery, and weather remain visible; Focus,
Screen Mirroring, Display, Sound, and Timer appear only while active; and
Spotlight, Bluetooth, AirDrop, Fast User Switching, Text Input, Time Machine,
Keyboard Brightness, and VPN remain hidden.

The `hostname` feature derives `<machine-type>-<chip-type>-<year>` from the Mac
family, Apple chip, and model year—for example, a 2024 MacBook Pro with an M4
Pro becomes `mbp-m4p-2024`. It reconciles the computer, Bonjour, and network
hostnames, requesting administrator authentication only when a name needs to
change.
