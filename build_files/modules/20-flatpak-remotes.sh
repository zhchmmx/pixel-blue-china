#!/bin/bash
# Flatpak repositories.
#
# The remote definition itself is the file shipped at
# system_files/etc/flatpak/remotes.d/flathub.flatpakrepo (placed in /etc by
# 00-system-files.sh, which overwrites the official-Flathub copy that the
# pixel-blue base image carries). It stays named `flathub` on purpose: every
# "add this remote from a .flatpakref" path in GNOME Software and Discover keys
# off that name, so a renamed remote would get the official one re-created
# underneath it.

set -ouex pipefail

# Upstream (fedora-silverblue) ships flatpak-add-fedora-repos.service, enabled
# via a systemd preset. On first boot it registers the Fedora flatpak registry
# (oci+https://registry.fedoraproject.org) plus a disabled fedora-testing
# remote. Mask the service so those are never added: they are slow here for the
# same reason Flathub is, and they would show up next to Flathub in the
# software centre's source list. Re-asserted here rather than inherited from
# the base so this image's mirror choice stands on its own.
#
# Note: this only affects fresh deployments of this image; an existing install
# that already added the Fedora remotes keeps them under /var/lib/flatpak.
ln -sfn /dev/null /etc/systemd/system/flatpak-add-fedora-repos.service
