#!/bin/bash
# Packages.

set -ouex pipefail

# The one thing this image has to do for Chinese input: a bootc system cannot
# install system packages itself, so without these the user has no way to get an
# IBus Rime engine at all.
#
# librime-lua is included because it is the dependency that bites: rime-ice and
# most other community presets run Lua processors, and Fedora does not pull the
# plugin in with ibus-rime. Everything above the engine -- schema choice,
# dictionaries, the input-source list -- is user state and is left to the user
# (see README, 中文适配).
#
# git is a runtime dependency of the shipped tool: `china-config rime install`
# and `rime update` clone and pull rime-ice. Same reason as the engine -- a bootc
# system cannot add packages after the fact, so without git nobody can update
# their own dictionaries. dnf5 is a no-op if the base image already ships it.
dnf5 install -y ibus-rime librime-lua git
