#!/usr/bin/env bash
set -oue pipefail

curator_git="--from git+https://codeberg.org/randogoth/curator/"

uvx $curator_git curator init
uvx $curator_git curator add brew:mc nix:micro nix:devbox
uvx $curator_git curator switch
uv tool install $curator_git curator