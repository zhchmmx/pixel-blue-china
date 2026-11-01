#!/bin/bash
# Flatpak repositories.
#
# Deliberate choice: this image ships NO Flathub default remote. Every user of
# this image arrives through `bootc switch`, and flatpak applies a
# /etc/flatpak/remotes.d/*.flatpakrepo file only once -- the name is recorded in
# the repo config's core.xa.applied-remotes list and the file is ignored from
# then on, so a file in /etc does nothing for switched machines while silently
# redirecting the rare fresh deployment. Two sources of truth, neither of them
# the user's decision.
#
# Instead the image ships one tool and its data files, both from system_files/
# (placed by 00-system-files.sh):
#
#   /usr/bin/china-config                          只改 /var/lib/flatpak 里的地址
#   /usr/share/china-config/remotes.d/*.flatpakrepo  可选源，文件名即别名
#   /usr/share/man/man1/china-config.1             中文手册
#
# Because the effective URL lives under /var, which the image cannot touch, the
# user's choice survives every subsequent `bootc switch` / `bootc upgrade` --
# nothing can "revert" it, and nothing can silently change it either.

set -ouex pipefail

# Sanity-check the shipped data files. Adding a mirror is meant to be just
# "drop a file in", so guard the one security-relevant invariant here: every
# candidate remote has to be a real remote definition, and every one of them
# must carry exactly the upstream Flathub signing key. A mirror that swaps the
# key is not a mirror.
reference_key=""
for repo in /usr/share/china-config/remotes.d/*.flatpakrepo; do
  test -r "$repo"
  test -n "$(awk 'index($0, "Url=") == 1 { print substr($0, 5); exit }' "$repo")"
  grep -q '^GPGKey=' "$repo"
  key=$(awk '/^GPGKey=/{flag=1} flag{print}' "$repo" | sha256sum | cut -d' ' -f1)
  if [ -z "$reference_key" ]; then
    reference_key="$key"
  fi
  test "$key" = "$reference_key" || {
    echo "GPGKey mismatch in $repo: mirrors must reuse the upstream Flathub key"
    exit 1
  }
done
test -x /usr/bin/china-config

# Upstream (fedora-silverblue) ships flatpak-add-fedora-repos.service, enabled
# via a systemd preset. On first boot it registers the Fedora flatpak registry
# (oci+https://registry.fedoraproject.org) plus a disabled fedora-testing
# remote. Mask the service so those are never added: they are slow here for the
# same reason Flathub is, and they would show up next to Flathub in the
# software centre's source list. Re-asserted here rather than inherited from
# the base so this image's behaviour stands on its own.
#
# Note: this only affects fresh deployments of this image; an existing install
# that already added the Fedora remotes keeps them under /var/lib/flatpak.
ln -sfn /dev/null /etc/systemd/system/flatpak-add-fedora-repos.service
