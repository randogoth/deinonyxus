#!/usr/bin/env bash
set -euo pipefail

# Append the base PRETTY_NAME to the custom name.
. /etc/os-release
custom="Deinonyxus (${PRETTY_NAME})"
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"${custom//\"/\\\"}\"|" /etc/os-release
