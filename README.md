<div align="center">
  <h1><img src="./data/icons/hicolor/scalable/apps/com.raggesilver.BlackBox.svg" height="64"/>Black Box</h1>
  <h4>An elegant and customizable terminal for GNOME</h4>
  <p>
    <a href="#features">Features</a> •
    <a href="#install">Install</a> •
    <a href="#gallery">Gallery</a> •
    <a href="./CHANGELOG.md">Changelog</a>
    <br/>
    <a href="https://gitlab.gnome.org/raggesilver/blackbox/-/wikis/home">Wiki</a> •
    <a href="./COPYING">License</a> •
    <a href="./CONTRIBUTING.md">Contributing</a>
  </p>
  <p>
  </p>
</div>

<div align="center">
  <img src="https://i.imgur.com/38c2eX4.png" alt="Preview"/><br/>
  <small><i>
    Black Box 0.14.0 (theme <a href="https://github.com/storm119/Tilix-Themes/blob/master/Themes/japanesque.json" target="_blank">"Japanesque"</a>, fetch <a href="https://github.com/Rosettea/bunnyfetch">bunnyfetch</a>)
  </i></small>
  <br/><br/>
</div>

## Features

- Color schemes - ([Tilix](https://github.com/gnunn1/tilix) compatible color scheme support)
- Theming - your color scheme can be used to style the whole app
- Background transparency
- Custom fonts, padding, and cell spacing
- Tabs
- Support for drag and dropping files
- Sixel (experimental)
- Customizable keybindings
- Toggle-able header bar
- Search your backlog with text or regex
- Context aware header bar - the header bar changes colors when running commands with sudo and in ssh sessions
- Desktop notifications - get notified when a command is finished in the background
- Customizable UI

## Install this split-panes build (Ubuntu 26.04)

These steps are for this personal copy, which adds split panes to the official
code. If a Black Box Flatpak is installed, remove it first, as it clashes with
this build.

Run all of these from a terminal:

```sh
# 1. Install what's needed to build it
sudo apt install git meson ninja-build valac gettext desktop-file-utils appstream \
  libgtk-4-dev libadwaita-1-dev libvte-2.91-gtk4-dev libjson-glib-dev \
  libpcre2-dev libxml2-dev librsvg2-dev libgee-0.8-dev libgraphene-1.0-dev

# 2. Get the code (skip if you already have this copy)
git clone -b split https://github.com/brianmcg/blackbox-terminal.git

# 3. Build and install it, from inside the code folder
cd blackbox-terminal
meson setup builddir --buildtype=release
ninja -C builddir
sudo ninja -C builddir install
```

Then open Black Box from the app launcher, or run `blackbox-terminal`. Your
font and theme are set in Preferences.

To remove it, run `sudo ninja -C builddir uninstall` from the code folder.

## Install

Black Box is packaged by the community for several distributions. See
[Repology](https://repology.org/project/blackbox-terminal/versions) for the
full list.

| Distribution | Package |
|---|---|
| Fedora | [![Fedora package](https://repology.org/badge/version-for-repo/fedora_44/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |
| Arch Linux (AUR) | [![AUR package](https://repology.org/badge/version-for-repo/aur/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |
| Ubuntu | [![Ubuntu package](https://repology.org/badge/version-for-repo/ubuntu_25_10/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |
| Debian | [![Debian package](https://repology.org/badge/version-for-repo/debian_13/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |
| Alpine Linux | [![Alpine package](https://repology.org/badge/version-for-repo/alpine_3_23/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |
| Manjaro | [![Manjaro package](https://repology.org/badge/version-for-repo/manjaro_stable/blackbox-terminal.svg)](https://repology.org/project/blackbox-terminal/versions) |

**Looking for an older release?**

Check out the [releases page](https://gitlab.gnome.org/raggesilver/blackbox/-/releases).

## Build from source

### Dependencies

- `valac` (Vala compiler)
- `meson` >= 0.50
- `gtk4` >= 4.12.0
- `libadwaita-1` >= 1.4
- `vte-2.91-gtk4` >= 0.69.0
- `json-glib-1.0` >= 1.4.4
- `gee-0.8` >= 0.20
- `libpcre2-8`
- `libxml-2.0` >= 2.9.12
- `librsvg-2.0` >= 2.54.0
- `graphene-gobject-1.0`

### Steps

```sh
meson setup builddir
ninja -C builddir
# If you want to install it
sudo ninja -C builddir install
```

## Translations

Black Box is accepting translations through Weblate! If you'd like to
contribute with translations, visit the
[Weblate project](https://hosted.weblate.org/projects/blackbox/).

<a href="https://hosted.weblate.org/projects/blackbox/blackbox/">
  <img src="https://hosted.weblate.org/widgets/blackbox/-/blackbox/multi-auto.svg" alt="Translation status" />
</a>

## Gallery

> Some of these screenshot are from older versions of Black Box.

<div align="center">
  <img src="https://i.imgur.com/O7Nblz8.png" alt="Black Box with 'Show Header bar' off"/><br/>
  <small><i>
    Black Box with "show header bar" off.
  </i></small>
  <br/><br/>
  <img src="https://i.imgur.com/CNwZhpJ.png" alt="Black Box with 'Show Header bar' off"/><br/>
  <small><i>
    Black Box with transparent background* and sixel support. *blur is controled
    by your compositor.
  </i></small>
  <br/><br/>
</div>

## Credits

- Most of Black Box's themes come (straight out copied) from [Tilix](https://github.com/gnunn1/tilix)
- Most non-Tilix-default themes come (straight out copied) from [Tilix-Themes](https://github.com/storm119/Tilix-Themes)
- Thank you, @linuxllama, for QA testing and creating Black Box's app icon
- Thank you, @predvodnik, for coming up with the name "Black Box"
- Source code that derives from other projects is properly attributed in the code itself
