# Deinonyxus &nbsp; [![bluebuild build badge](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml/badge.svg)](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml)

*Deinonyxus* is a personal spin of the UBlue Bluefin DX image with the 🍦[Lix](https://lix.systems/) flavored Nix package manager baked in.

## What’s inside
- Base: `ghcr.io/ublue-os/bluefin-dx:latest` without Cockpit, Docker, Firefox, VS Code
- System packages added: `dms`, `ghostty`, `labwc`, `labwc-menu-generator`, `thunar`, `syncthing`, `uv`, `vscodium`, `waydroid`, `jq`
- System flatpaks added: Telegram Desktop, Waterfox browser

## Sessions
- GNOME stays default; pick it as usual at the login screen.
- Labwc + DankMaterialShell is available as an alternate Wayland session (choose “Labwc” from the GDM gear menu). `/etc/xdg/labwc/autostart` imports session env, starts DMS, and enables the user units.
- Labwc menu generation and theming mirror the Nix config: menu updates on app/Flatpak changes, theming/rofi follow DMS colors, and rc.xml supplies the default keybinds (including `rofi -show drun` on Super release).
- GNOME apps run fine under labwc; GNOME Shell-only UI (overview, extensions) remains GNOME-only.

## Just Recipes
- `upgrade-nix`: upgrades to the latest version of Lix via the user profile. Replaces `nix upgrade-nix` which does not work with an immutable lowerdir `/nix/store` folder
- `install-nix-software-center`: installs a graphical app store for Nix packages

## Install / Rebase

```bash
# First pull unsigned to get signing policy
rpm-ostree rebase ostree-unverified-registry:ghcr.io/randogoth/deinonyxus:latest
systemctl reboot

# Then move to the signed image
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/randogoth/deinonyxus:latest
systemctl reboot
```

The `latest` tag always tracks the latest build for the Fedora base set in `recipes/recipe.yml`.

## Building locally
```bash
bluebuild build
```

## Signature verification
Images are signed with Sigstore/cosign. Verify with the repo's `cosign.pub`:
```bash
cosign verify --key cosign.pub ghcr.io/randogoth/deinonyxus
```
