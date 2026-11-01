#!/bin/bash
# Packages.

set -ouex pipefail

# The one thing this image has to do for Chinese input: a bootc system cannot
# install system packages itself, so without these two the user has no way to
# get an IBus Rime engine at all.
#
# librime-lua is included because it is the dependency that bites: rime-ice and
# most other community presets run Lua processors, and Fedora does not pull the
# plugin in with ibus-rime. Everything above the engine -- schema choice,
# dictionaries, the input-source list -- is user state and is left to the user
# (see README, 中文适配).
dnf5 install -y ibus-rime librime-lua
