#!/bin/bash
#
# Build driver. The actual work lives in build_files/modules/, executed in
# filename order (the zero-padded numeric prefix is the order), same convention
# as the pixel-blue base image.
#
# Ordering is load-bearing:
#   00-system-files.sh   copy system_files/ to / (must run first: the
#                        china-config tool, its mirror data files and the man
#                        page all come from there, and later modules check them)
#   10..20               package installs, systemd presets
#   30-user-services.sh  systemctl --global enable for user units; after 00,
#                        because the unit files it enables ship in system_files/
#   95-cleanup.sh        trim the dnf cache, last
#
# The gaps in the numbering are deliberate: they leave room for the modules this
# image will grow (proxy tooling), without renumbering what already exists.
#
# Modules are standalone bash scripts, each with its own `set -ouex pipefail`,
# so they can also be run individually while debugging. The Containerfile keeps
# the whole build in a single RUN layer: the modules share the same container
# filesystem and dnf cache, and splitting into more RUN steps would only add
# layers.

set -ouex pipefail

for module in /ctx/modules/*.sh; do
  echo "=== running $(basename "$module")"
  bash "$module"
done
