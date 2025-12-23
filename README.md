# randofin-os &nbsp; [![bluebuild build badge](https://github.com/randogoth/randofin-os/actions/workflows/build.yml/badge.svg)](https://github.com/randogoth/randofin-os/actions/workflows/build.yml)

randofin-os is a personal spin of the UBlue Bluefin DX image with Nix baked in and a first-login bootstrap for home-manager packages.

## What’s inside
- Base: `ghcr.io/ublue-os/bluefin-dx:latest` without Cockpit, Docker, Firefox, VS Code
- Nix: multi-user install baked in; `nix-overlay.service` and `nix-daemon.service` enabled.
- First-login bootstrap: installs nix packages `uv micro vscodium mc` via `home-manager`.
- System packages added: `syncthing`, `waydroid`;
- System flatpaks added: Telegram Desktop, Waterfox

## First login behavior
- Triggers for each non-root user on their first session.
- Writes state to `~/.local/state/randofin-os/nixpkgs-init.done`; delete it to rerun.
- Bootstraps `~/.config/home-manager/home.nix` and runs `home-manager switch` with the package set above.

## Install / Rebase
> [!WARNING]
> Uses the Fedora Atomic native container workflow.

```bash
# First pull unsigned to get signing policy
rpm-ostree rebase ostree-unverified-registry:ghcr.io/randogoth/randofin-os:latest
systemctl reboot

# Then move to the signed image
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/randogoth/randofin-os:latest
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
cosign verify --key cosign.pub ghcr.io/randogoth/randofin-os
```
