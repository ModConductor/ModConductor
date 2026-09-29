#!/usr/bin/env bash
set -euo pipefail
[[ $1 == --rid && $2 == linux-x64 && $3 == --publish-directory && -d $4 ]] || { echo "Expected Linux x64 publish directory" >&2; exit 2; }
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  libegl1 libgles2 libgtk-3-0t64 libepoxy0 libsecret-1-0 libicu74 \
  libunwind8 libssl3t64 zlib1g libglib2.0-bin fontconfig fonts-dejavu-core \
  gsettings-desktop-schemas xdg-utils shared-mime-info xvfb xauth xdotool
