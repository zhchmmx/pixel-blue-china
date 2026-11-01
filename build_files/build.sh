#!/bin/bash
#
# Build driver. The actual work lives in build_files/modules/, executed in
# filename order (the zero-padded numeric prefix is the order), same convention
# as the pixel-blue base image.
#
# Ordering is load-bearing:
#   00-system-files.sh   copy system_files/ to / (must run first: the Flatpak
#                        remote, the gschema override and the user unit all come
#                        from there)
#   10..20               package installs, the rime-ice payload, systemd presets
#   50-schemas.sh        glib-compile-schemas, after every operation that can
#                        add schema files or overrides
#   55-user-services.sh  systemctl --global enable, after the unit files exist
#   95-cleanup.sh        trim the dnf cache, last
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
