#!/bin/bash
#
# china-config warp-optip uninstall 的包装脚本：直接跑镜像里烘好的上游
# uninstall.sh，参数全部透传（--purge、--keep-connection 等由上游解释）。
#
# 上游仓库：https://github.com/zhchmmx/warp-optip

set -euo pipefail

exec /usr/libexec/warp-optip/uninstall.sh "$@"
