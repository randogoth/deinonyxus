#!/usr/bin/env bash
set -oue pipefail
nix run github:nix-community/home-manager/release-25.11 -- init --switch

pkgs='uv micro vscodium mc'
f=~/.config/home-manager/home.nix
tmp="$(mktemp)"
{
  echo "  home.packages = ["
  for p in $pkgs; do echo "    pkgs.$p"; done
  echo "  ];"
} > "$tmp"

sed -i "/^[[:space:]]*home\.packages[[:space:]]*=[[:space:]]*\[/,/^[[:space:]]*];[[:space:]]*$/{
  /^[[:space:]]*home\.packages[[:space:]]*=/{
    r $tmp
  }
  d
}" "$f"

rm -f "$tmp"

home-manager switch
