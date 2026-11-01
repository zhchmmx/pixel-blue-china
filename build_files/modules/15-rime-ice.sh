#!/bin/bash
# 雾凇拼音 (rime-ice) factory configuration.
#
# The preset is fetched at build time and stored read-only in the image under
# /usr/share/pixel-blue-cn/rime/. It is NOT placed in /etc/skel or any home
# directory: /var and /home are user state on a bootc image and cannot carry
# image content. The per-user seeding happens at first login, through the
# pixel-blue-cn-rime-seed.service user unit (see 55-user-services.sh and
# system_files/usr/share/pixel-blue-cn/rime-seed.sh).
#
# Build-time download is fine even though this image targets China: the build
# runs in GitHub Actions, and the pinned archive is checksum-verified, so the
# image content is reproducible and never depends on a mirror at runtime.

set -ouex pipefail

# Bump both values together to update the preset. The tag tarball is the
# rime-ice tree itself; the nightly release assets are rebuilt continuously and
# therefore not usable as a pin.
RIME_ICE_REF="2026.06.30"
RIME_ICE_SHA256="ae1d8af6f4525e2454dd0afc7f583833d5a534e22889fb31ad62bace92fa1177"
RIME_ICE_URL="https://github.com/iDvel/rime-ice/archive/refs/tags/${RIME_ICE_REF}.tar.gz"

FACTORY="/usr/share/pixel-blue-cn/rime"

# /tmp is a tmpfs mount in the Containerfile, so the tree disappears with the
# build even if the cleanup below is skipped.
WORK="$(mktemp -d /tmp/rime-ice.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT

curl -fSL --retry 3 -o "$WORK/rime-ice.tar.gz" "$RIME_ICE_URL"
echo "${RIME_ICE_SHA256}  $WORK/rime-ice.tar.gz" | sha256sum --check --status

mkdir -p "$WORK/src"
tar -xzf "$WORK/rime-ice.tar.gz" -C "$WORK/src" --strip-components=1

mkdir -p "$FACTORY"
cp -a "$WORK/src"/. "$FACTORY"/

# Drop the repository scaffolding; everything else in the archive is
# configuration a schema can reference. squirrel.yaml and weasel.yaml stay on
# purpose -- they are the macOS/Windows counterparts rime-ice keeps in the same
# directory, and together they cost 48K.
rm -rf "$FACTORY/.github" "$FACTORY/.gitignore" "$FACTORY/AGENTS.md" \
  "$FACTORY/README.md" "$FACTORY/recipe.yaml" "$FACTORY/build"

# Fail the build instead of shipping an image whose preset cannot be seeded.
test -f "$FACTORY/default.yaml"
test -f "$FACTORY/rime_ice.schema.yaml"
test -d "$FACTORY/lua"
test -d "$FACTORY/cn_dicts"
