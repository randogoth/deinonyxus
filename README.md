# Deinonyxus &nbsp; [![bluebuild build badge](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml/badge.svg)](https://github.com/randogoth/deinonyxus/actions/workflows/build.yml)

*Deinonyxus* is a personal spin of the UBlue Bluefin DX image with experimental Nix package manager baked in (borrowed from the great [Daemonix](https://github.com/DXC-0/daemonix/) image) and a first-login bootstrap for `nix/home-manager`-like declarative package management using [curator](https://codeberg.org/randogoth/curator).

## What’s inside
- Base: `ghcr.io/ublue-os/bluefin-dx:latest` without Cockpit, Docker, Firefox, VS Code
- Nix: multi-user install baked in; `nix-overlay.service` and `nix-daemon.service` enabled.
- First-login bootstrap: installs nix packages `devbox`, `mc`, `micro`, and `vscodium` via `curator`.
- System packages added: `syncthing`, `uv`, `waydroid`;
- System flatpaks added: Telegram Desktop, Waterfox

## First login behavior
- Triggers for each non-root user on their first session.
- Writes state to `~/.local/state/deinonyxus/curator-init.done`; delete it to rerun.
- Bootstraps `~/.config/curator/inventory.toml` and runs `curator switch` with the packages set above.

## Install / Rebase
> [!WARNING]
> Uses the Fedora Atomic native container workflow.

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
bluebuild build --recipe recipes/recipe.yml
```

## Signature verification
Images are signed with Sigstore/cosign. Verify with the repo's `cosign.pub`:
```bash
cosign verify --key cosign.pub ghcr.io/randogoth/deinonyxus
```