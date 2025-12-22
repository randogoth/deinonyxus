#!/usr/bin/env bash
set -euo pipefail

rpm_url="https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm"

install -d /usr/share/nix-store /var/lib/nix-store /var/cache/nix-store /nix

dnf install -y "$rpm_url"

# Move the pre-populated store out of /nix so it can serve as the immutable lowerdir.
if compgen -G "/nix/*" >/dev/null; then
  mv /nix/* /usr/share/nix-store/
fi
