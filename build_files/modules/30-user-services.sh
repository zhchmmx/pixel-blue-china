#!/bin/bash
# Enable user services.
#
# One unit here, and it exists for one bug: inside the Flatpak sandbox
# fontconfig trusts the host font cache it is handed, reports "skipping, cache
# in /var/cache/fontconfig is up to date" for /run/host/fonts, and ends up with
# zero CJK faces -- so Chinese text in com.tencent.WeChat renders as boxes.
# /run/host/user-fonts (backed by ~/.local/share/fonts) is scanned through a
# different path and is not affected. Details and reproduction:
# https://github.com/zhchmmx/pixel-blue-china/issues/6, upstream
# https://github.com/flatpak/flatpak/issues/6738.
#
# Both pieces come from system_files/ and are placed by 00-system-files.sh, so
# this module has to run after it:
#
#   /usr/lib/systemd/user/china-config-fonts.service   oneshot, every login
#   /usr/libexec/china-config-fonts.sh                the actual copy
#
# Why a login-time unit instead of /etc/skel: skel is only read when an account
# is created, and essentially everyone on this image arrives through
# `bootc switch` with a home directory that already exists -- exactly the users
# skel cannot reach. `--global enable` puts a symlink in
# /etc/systemd/user/default.target.wants instead, which takes effect for those
# same users on their next login.
#
# Why a per-user copy and nothing cleverer: a symlink into /usr/share/fonts is
# dead inside the sandbox, and flatpak overrides / FONTCONFIG_PATH do not
# restore the missing faces either (all verified by hand). So each user gets a
# real copy of whatever `fc-list :lang=zh` finds on that machine -- four Noto
# CJK files, no more. The image does not install a font package for this: the
# fonts already on a given machine may come from the image, from an install-time
# langpack, or from something the user added, and only fc-list knows.
#
# The unit runs on every login but the script only copies when the target is
# missing or the host copy is newer, so the steady-state cost is one fc-list
# and a few stat calls. Once flatpak or the runtime fixes the cache decision,
# drop this module, the unit and the script together; nothing under /var is
# touched and the leftover files in ~/.local/share/fonts are then simply
# redundant.

set -ouex pipefail

systemctl --global enable china-config-fonts.service
