#!/bin/bash
# Trim the package cache so it does not end up in an image layer.

set -ouex pipefail

dnf5 clean all
