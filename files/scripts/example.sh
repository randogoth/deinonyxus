#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

sudo chmod 755 /usr/local/sbin/bls-add-bluefin.sh
sudo systemctl daemon-reload