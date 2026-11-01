#!/bin/bash
# Enable user services.
#
# --global enable writes into /etc/systemd/user/global/, which is part of the
# image, and the unit then runs in every user's session on login. This is the
# only way to seed per-user files on a bootc image: /home and /var are user
# state and cannot carry image content, and /etc/skel would only cover users
# created after the first boot.

set -ouex pipefail

systemctl --global enable pixel-blue-cn-rime-seed.service
