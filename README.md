# settings-kde

**Mac Settings for KDE Plasma**: KDE's
[System Settings](https://invent.kde.org/plasma/systemsettings) laid out
and styled like macOS's System Settings (Sequoia and later).

Based on System Settings 6.7.5. Every change is a commit on top of the
`v6.7.5` tag, and the upstream code is marked `MacSettings:` where it was
changed. All of KDE's settings pages (KCMs) are the stock ones, unchanged;
only the app around them is different.

## What's different from System Settings

- **Window**: frameless, rounded, with stoplights (close, minimize, zoom)
  in the corner, a native shadow, and a translucent glass sidebar that runs
  to the top of the window. Drag empty space at the top to move;
  double-click to zoom.
- **Sidebar**: a search field, your account (name and picture; opens Users),
  then macOS's groups with coloured tile icons: Wi‑Fi, Bluetooth, Network ·
  Notifications, Sound · General, Appearance, Accessibility, Spotlight,
  Privacy & Security · Desktop & Dock, Displays, Wallpaper, Battery ·
  Lock Screen, Users & Groups, Passwords · Internet Accounts, Game
  Controllers · Keyboard, Mouse, Trackpad, Printers & Scanners · and the
  rest (tablets, touchscreens, disks, discs). Each entry maps to KDE's pages
  (`app/qml/Entries.js`); entries whose pages aren't installed or don't
  apply here are left out.
- **Lists of pages**: entries covering several of KDE's pages (General,
  Appearance, Desktop & Dock…) open a macOS-style list of them in rounded
  groups; open one and ‹ takes you back.
- **Pages**: headers blend into the page with a bold title. Forms are
  macOS's grouped panels: Kirigami's new forms in their "cards" style, and
  classic Kirigami form layouts decorated with a rounded panel behind each
  section, left-aligned labels and section titles. No Help button (F1
  still works) and no icons on the buttons.

The macOS controls (buttons, checkboxes, pop-up buttons, sliders, segmented
tabs) come from the MacGlass widget style in
[kde-mac-glass](https://github.com/jingledingle521/kde-mac-glass), which this
is part of.

## Install

```sh
sudo dnf builddep plasma-systemsettings      # first time (Fedora)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local/opt/settings -DBUILD_TESTING=OFF
ninja -C build install
```

It installs next to the stock app. To have the desktop open it (the
launcher, other apps' "Configure…" buttons), put a `systemsettings` ahead of
`/usr/bin` in your `PATH`:

```sh
cat > ~/.local/bin/systemsettings <<'EOF'
#!/bin/sh
exec "$HOME/.local/opt/settings/bin/systemsettings" "$@"
EOF
chmod +x ~/.local/bin/systemsettings
```

Delete that file to go back to the stock app. kde-mac-glass's
`./install.sh --settings` does all of this.

## Upstream

System Settings is © the KDE community, and this keeps its licenses
(GPL-2.0-or-later and others; see [LICENSES](LICENSES)). The window frame is
shared with [finder-kde](https://github.com/jingledingle521/finder-kde). Not
affiliated with KDE or Apple.
