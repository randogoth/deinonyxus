#!/usr/bin/env bash

set -xueo pipefail

diff=$(realpath 20-chicago95.diff)

# Fetch
TMPDIR=$(mktemp -d)
cd "$TMPDIR"
# TODO: add renovate
CHICAGO95_SHA=6b6ef76c58e2078c913420278b5e17e0aa566374
wget https://github.com/grassmunk/Chicago95/archive/${CHICAGO95_SHA}.zip
unzip -q *.zip
mv Chicago95* /usr/src/chicago95
cd /usr/src/chicago95

# TODO: upstream this patch
patch -p1 <$diff

# Themes
cp -r Theme/Chicago95 /usr/share/themes

## 23-b00merang.sh
wget https://github.com/B00merang-Project/Windows-95/archive/refs/heads/master.zip
unzip master.zip
mv ./Windows-95-master/gtk-4.0 /usr/share/themes/Chicago95/

# Icons and cursors
cp -r Icons/* Cursors/* /usr/share/icons/

# Fonts
cp Fonts/vga_font/LessPerfectDOSVGA.ttf /usr/share/fonts
cp -r Fonts/bitmap/cronyx-cyrillic /usr/share/fonts

## 22-fonts.sh
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/CascadiaMono.zip
unzip CascadiaMono.zip
mv CaskaydiaMonoNerdFont-Regular.ttf /usr/share/fonts
fc-cache -fv

# Use Qt instead of GTK if possible
mkdir -p /usr/share/qt5ct/colors
cp Extras/Chicago95_qt.conf /usr/share/qt5ct/colors

# Sounds
cp -Rf sounds/Chicago95 /usr/share/sounds/
cp -f "Extras/Microsoft Windows 95 Startup Sound.ogg" /usr/share/sounds/Chicago95/startup.ogg

cp -f ./sounds/chicago95-startup.desktop /etc/skel/.config/autostart

# Backgrounds
cp -Rf ./Extras/Backgrounds /usr/share/backgrounds/Chicago95

## 24-wallpapers.sh
URLS=(
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/256color%20%28large%29.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/Concrete.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/FLOCK.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/SLASH.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/SPOTS.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/STEEL.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/TARTAN.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/arcade.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/arches.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/argyle.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/ball.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/cars.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/castle.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/chitz.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/egypt.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/honey.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/leaves.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/marble.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/redbrick.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/rivets.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/squares.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/thatch.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/winlogo.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-2.%20Windows%203.1x%20and%20NT%203.x/zigzag.bmp"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/BOXES.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/CHESS.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/PAPER.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/PARTY.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/PYRAMID.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/RIBBONS.BMP"
  "https://archive.org/download/microsoft-windows-wallpapers-pictures/1-1.%20Windows%203.0/WEAVE.BMP"
)
TARGET_DIR="/usr/share/backgrounds/Chicago95/Wallpaper"

printf "%s\n" "${URLS[@]}" | xargs -n 1 -P 10 -I{} wget -P "$TARGET_DIR" "{}"

rm -rf "$TMPDIR"