#!/usr/bin/env bash
set -euo pipefail

rpm_url="https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm"

install -d /usr/share/nix-store /var/lib/nix-store /var/cache/nix-store /nix

# Avoid systemd calls during RPM %post in the image build environment.
export SYSTEMD_OFFLINE=1

# Install the RPM; allow missing GPG key since we fetch directly by URL.
dnf install -y --nogpgcheck "$rpm_url"

# Move the pre-populated store out of /nix so it can serve as the immutable lowerdir.
if compgen -G "/nix/*" >/dev/null; then
  mv /nix/* /usr/share/nix-store/
fi

# The RPM %post handles sysusers/tmpfiles; if we ran with SYSTEMD_OFFLINE the
# post scripts are still executed, so no extra calls are needed here.
