#!/bin/bash
#
# china-config warp-optip install 的包装脚本：把镜像里烘好的 warp-optip 和
# 预下载的二进制接到上游 install.sh 上。
#
# 刻意不做任何检查：root 权限、nmcli / wg 这些依赖、连接状态都由上游
# install.sh 自己判断和报错，这个包装只负责一件事 —— 不带参数直接跑时，默认
# 注入 --no-download 和 vendor/ 里预下载的二进制（wgcf、warp 扫描器，构建时
# 已经下好），让安装过程不联网下载任何东西；用户手动传了 --no-download /
# --wgcf-bin / --warp-bin 里的任何一个，该项就以用户传的为准，包装不再重复
# 注入。其余参数一律原样透传。
#
# 上游仓库：https://github.com/zhchmmx/warp-optip
# 程序装到 /usr/local（bootc 上即可写的 /var/usrlocal），配置在 /etc，账号和
# 状态在 /var/lib/warp-optip —— 都不在镜像管的地方，bootc 升级不会冲掉。

set -euo pipefail

WO_DIR=/usr/libexec/warp-optip
VENDOR_DIR="$WO_DIR/vendor"

# 用户已经手动指定了哪些默认项，谁指定的就不重复注入。上游解析器只认
# "--wgcf-bin PATH" 这种分开写的形式，所以这里也只匹配这一种。
HAS_NO_DOWNLOAD=0
HAS_WGCF_BIN=0
HAS_WARP_BIN=0
for a in "$@"; do
    case "$a" in
        --no-download) HAS_NO_DOWNLOAD=1 ;;
        --wgcf-bin) HAS_WGCF_BIN=1 ;;
        --warp-bin) HAS_WARP_BIN=1 ;;
    esac
done

# vendor/ 里同时有 vendor/warp 和 vendor/wgcf_*_linux_amd64，上游安装器本来就
# 会按这套约定自己找到它们；--wgcf-bin/--warp-bin 只是把选择钉得更明确。
# 注意：bash 4.4+ 在 nullglob 下、数组赋值里的无匹配 glob 会保留字面量，所以
# 这里逐个 -f 过滤；匹配不到就不传该选项，落回上游的本地查找逻辑。
shopt -s nullglob
WGCF_BIN=""
for f in "$VENDOR_DIR"/wgcf_*_linux_amd64; do [[ -f $f ]] && { WGCF_BIN=$f; break; }; done
WARP_CANDIDATE="$VENDOR_DIR/warp-linux-amd64"
WARP_BIN=""
[[ -f $WARP_CANDIDATE ]] && WARP_BIN=$WARP_CANDIDATE

ARGS=()
((HAS_NO_DOWNLOAD == 0)) && ARGS+=(--no-download)
((HAS_WGCF_BIN == 0)) && [[ -n $WGCF_BIN ]] && ARGS+=(--wgcf-bin "$WGCF_BIN")
((HAS_WARP_BIN == 0)) && [[ -n $WARP_BIN ]] && ARGS+=(--warp-bin "$WARP_BIN")

exec "$WO_DIR/install.sh" "${ARGS[@]}" "$@"
