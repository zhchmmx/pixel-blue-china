#!/bin/sh
# Copy the read-only 雾凇拼音 tree that the image ships into the IBus Rime user
# directory. Runs as the user, from pixel-blue-cn-rime-seed.service, once per
# account.
#
# cp -Rn never overwrites an existing file, so a configuration the user has
# edited or a dictionary they added themselves survives. Files that are new to
# them land with the current timestamp, which is what makes librime rebuild its
# tables on the next deploy instead of reusing a stale build/ directory.
#
# Consequence worth knowing: an account that already had its own default.yaml
# keeps it, and therefore keeps its own schema list. To take the image preset as
# the starting point, move ~/.config/ibus/rime away and remove the marker below.

set -eu

FACTORY=/usr/share/pixel-blue-cn/rime
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"
RIME_HOME="${CONFIG_HOME}/ibus/rime"
MARKER="${CONFIG_HOME}/pixel-blue-cn/rime-seed.stamp"

if [ ! -d "$FACTORY" ]; then
  echo "rime-seed: $FACTORY is missing, nothing to do" >&2
  exit 0
fi

mkdir -p "$RIME_HOME"
cp -Rn "$FACTORY"/. "$RIME_HOME"/

mkdir -p "${MARKER%/*}"
: >"$MARKER"

echo "rime-seed: 雾凇拼音 is in place at ${RIME_HOME}"
