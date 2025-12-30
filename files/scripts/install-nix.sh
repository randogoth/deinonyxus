#!/usr/bin/env bash
set -euo pipefail

rpm_url="https://nix-community.github.io/nix-installers/lix/x86_64/lix-multi-user-2.91.1.rpm"

install -d /usr/share/nix-store /var/lib/nix-store /var/cache/nix-store /nix /etc/nix

# Avoid systemd calls during RPM %post in the image build environment.
export SYSTEMD_OFFLINE=1

# Install the RPM; allow missing GPG key since we fetch directly by URL.
dnf install -y --nogpgcheck "$rpm_url"

nix_conf=/etc/nix/nix.conf
lix_cache_url="https://cache.lix.systems/"
lix_cache_key="cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="

ensure_list_value() {
  local key="$1" value="$2" escaped_value
  escaped_value=$(printf '%s' "$value" | sed 's/[\\&]/\\&/g')

  touch "$nix_conf"

  if grep -Eq "^${key}[[:space:]]*=.*${escaped_value}" "$nix_conf"; then
    return
  fi

  if grep -Eq "^${key}[[:space:]]*=" "$nix_conf"; then
    sed -i "s|^${key}[[:space:]]*= *\\(.*\\)|${key} = \\1 ${escaped_value}|" "$nix_conf"
  else
    echo "${key} = ${value}" >>"$nix_conf"
  fi
}

ensure_list_value "substituters" "$lix_cache_url"
ensure_list_value "trusted-public-keys" "$lix_cache_key"

# # Ensure the overlay mount service is enabled so /nix is populated on boot.
# mkdir -p /etc/systemd/system/multi-user.target.wants
# ln -sf /usr/lib/systemd/system/nix-overlay.service /etc/systemd/system/multi-user.target.wants/nix-overlay.service

# Move the pre-populated store out of /nix so it can serve as the immutable lowerdir.
if compgen -G "/nix/*" >/dev/null; then
  mv /nix/* /usr/share/nix-store/
fi

# The RPM %post handles sysusers/tmpfiles; if we ran with SYSTEMD_OFFLINE the
# post scripts are still executed, so no extra calls are needed here.
