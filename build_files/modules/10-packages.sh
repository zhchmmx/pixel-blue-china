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

# libfuse2, so published .AppImage files can actually run here.
#
# Fedora removed fuse(2) from the Atomic desktop images on purpose (ostree sig
# issue #50), and the AppImage runtime needs libfuse.so.2 to mount itself --
# without that library an AppImage simply refuses to start. That matters for
# proxy tooling: managing a Clash subscription graphically today means a client
# like FlClash, and it ships deb, rpm and AppImage for Linux. On an ostree
# system the first two only come in as a client-side `rpm-ostree` layer (the
# weak path under bootc, and it drops payload into /opt, which here is still a
# symlink into the mutable /var/opt), while the AppImage is one upstream
# artifact the user can run exactly as published -- provided libfuse.so.2 is
# there. Reassembling it by hand would run something we put together ourselves
# instead, which is worse for checksums and for updates alike.
#
# Scope is deliberately one library package, nothing else: no GUI client, no
# proxy core, no service. This is against the current upstream direction, so
# assert the soname the runtime looks for. Fedora now carries a separate `fuse2`
# source package too; if the provider is ever renamed, the build must fail here
# rather than quietly ship an image that cannot mount AppImages.
dnf5 install -y fuse-libs
test -e /usr/lib64/libfuse.so.2
