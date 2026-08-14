# Dotfiles

Personal dotfiles orchestrated by [dof](https://github.com/notwillk/dof).

The transitional `default` feature uses Rulesy to install GPG and GNU Stow,
then checks and reconciles the existing `home/` payload through a shared Stow
lifecycle helper. The feature hook itself retains only Rulesy bootstrap,
copied `initial-files/`, and the special Codex config link. Human-facing
update and recovery notes are installed as `managed_by_dofiles.md`.

GPG and Stow use the first supported package manager already present on the
machine, with Homebrew preferred before the supported system managers. A
missing prerequisite fails before home links, copied initial files, or the
Codex link are changed. This remains post-bootstrap maintenance: dof's own
installer must still be able to complete before the default feature can run.
Fresh installs leave `macos-gui` disabled so bootstrap does not install apps or
change GUI preferences implicitly. Enable it explicitly, then apply:

```sh
"$HOME/.dof/bin/dof" feature enable macos-gui
"$HOME/.dof/bin/dof" apply
```

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
