# Deinonyxus &nbsp; [![bluebuild build badge](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml/badge.svg)](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml)

*Deinonyxus* is a personal spin of the UBlue Bluefin DX image with the 🍦[Lix](https://lix.systems/) flavored Nix package manager baked in and a first-login bootstrap for simple declarative package management using [curator](https://codeberg.org/randogoth/curator).

The overlay mount approach was directly borrowed from the [Daemonix](https://github.com/DXC-0/daemonix/) Silverblue/Nix image.

## What’s inside
- Base: `ghcr.io/ublue-os/bluefin-dx:latest` without Cockpit, Docker, Firefox, VS Code
- Lix: multi-user install baked in with persistence at `/var/home/nix`; `nix-daemon.service` enabled.
(D) - First-login bootstrap: installs Lix/nix packages `devbox`, `mc`, and `micro` via `curator`
- System packages added: `syncthing`, `uv`, `vscodium`, `waydroid`;
- System flatpaks added: Telegram Desktop, Zen Browser

## First login
- Triggers for each non-root user on their first session.
- Writes state to `~/.local/state/deinonyxus/curator-init.done`; delete it to rerun.
- Bootstraps `~/.config/curator/inventory.toml` and runs `curator switch` with the packages set above.

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
