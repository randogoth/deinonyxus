#!/usr/bin/env bash
set -oue pipefail

curator_pkg="git+https://codeberg.org/randogoth/curator/"

uvx --from "$curator_pkg" curator init
uvx --from "$curator_pkg" curator add nix:mc nix:micro nix:devbox
uvx --from "$curator_pkg" curator switch
uv tool install "$curator_pkg"
