#!/bin/bash
# Copy the contents of system_files/ of the git repo to /.

set -ouex pipefail

cp -avf "/ctx/system_files"/. /
