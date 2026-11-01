#!/bin/bash
# Compile the GSettings defaults.
#
# system_files/usr/share/glib-2.0/schemas/zz9-pixel-blue-cn.gschema.override
# pins the default input sources so Rime is present without the user visiting
# Settings -> Keyboard. glib-compile-schemas reads *.gschema.override files in
# sorted-filename order and an override replaces a whole key, so the file is
# named zz9- to sort after the base image's zz0-pixel-blue-modifications, in
# case the two ever touch the same key.
#
# Like every gsettings default this only applies to users who have never
# changed their input sources; anyone who already has a value in dconf keeps it.
# Must run after all package operations, so that packages installed earlier in
# the build have had a chance to ship their own schema files.

set -ouex pipefail

glib-compile-schemas /usr/share/glib-2.0/schemas
