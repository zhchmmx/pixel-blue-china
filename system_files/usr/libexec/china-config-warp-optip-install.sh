#!/bin/bash
#
# china-config warp-optip install 的包装脚本：把镜像里烘好的 warp-optip 和
# 预下载的二进制接到上游 install.sh 上，参数全部透传。
#
# 刻意不做任何检查：root 权限、nmcli / wg 这些依赖、连接状态都由上游
# install.sh 自己判断和报错，这个包装只负责一件事 —— 让安装过程不联网下载
# 第三方二进制（wgcf、warp 扫描器都在 vendor/ 里，构建时已经下好）。
#
# 上游仓库：https://github.com/zhchmmx/warp-optip
# 程序装到 /usr/local（bootc 上即可写的 /var/usrlocal），配置在 /etc，账号和
# 状态在 /var/lib/warp-optip —— 都不在镜像管的地方，bootc 升级不会冲掉。

set -euo pipefail

WO_DIR=/usr/libexec/warp-optip
VENDOR_DIR="$WO_DIR/vendor"

# vendor/ 里同时有 vendor/warp 和 vendor/wgcf_*_linux_amd64，上游安装器本来就
# 会按这套约定自己找到它们；--wgcf-bin/--warp-bin 只是把选择钉得更明确。glob
# 匹配不到时（nullglob）不传该选项，落回上游的本地查找逻辑。
shopt -s nullglob
WGCF_MATCH=("$VENDOR_DIR"/wgcf_*_linux_amd64)
WARP_MATCH=("$VENDOR_DIR"/warp-linux-amd64)

ARGS=(--no-download)
((${#WGCF_MATCH[@]})) && ARGS+=(--wgcf-bin "${WGCF_MATCH[0]}")
((${#WARP_MATCH[@]})) && ARGS+=(--warp-bin "${WARP_MATCH[0]}")

exec "$WO_DIR/install.sh" "${ARGS[@]}" "$@"
