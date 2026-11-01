#!/bin/bash
# Packages.

set -ouex pipefail

# Chinese input method: ibus front-end + the librime Lua module. rime-ice
# (15-rime-ice.sh) needs Lua; Fedora does not pull the plugin in automatically.
dnf5 install -y ibus-rime librime-lua
