#!/usr/bin/env bash
set -oue pipefail

uv tool install --from git+https://codeberg.org/randogoth/curator/ curator

curator init
curator add brew.mc
curator add nix.micro
curator add nix.vscodium
curator switch