#!/bin/bash
# Cloudflare WARP endpoint 优选工具 warp-optip（https://github.com/zhchmmx/warp-optip）。
#
# 镜像烘进去的是「料」，不是「装好的状态」：构建时克隆上游最新 main 到
# /usr/libexec/warp-optip（安装脚本运行时要读同一目录里的 lib/、bin/、
# dispatcher/、systemd/，这份源码不能扔），并把安装所需的两个第三方二进制
# 提前下载到 vendor/ 子目录：
#
#   - wgcf：GitHub ViRb3/wgcf 的最新 release（构建时查版本号）。
#   - warp：Misaka-blog/warp-script 的优选扫描器。
#
# 上游安装器支持 --wgcf-bin/--warp-bin 加 --no-download，指到这两个文件后运行
# 时不再下载任何东西；wgcf 的注册要访问 Cloudflare API，那一步留给用户在网络
# 可达时执行。
#
# 产物固定 amd64：本镜像只适配 Pixel 6 这一款设备，不做架构自适应，也不为其他
# 架构出产物。
#
# 跟随上游最新版本、不 pin：warp-optip 由本镜像作者维护。接口对不上时下面的
# 冒烟测试和安装脚本自身会失败，构建直接挂，不会静默产出坏镜像。

set -ouex pipefail

WO_DIR=/usr/libexec/warp-optip
VENDOR_DIR="$WO_DIR/vendor"

# 本镜像唯一的构建目标架构。
WO_ARCH=amd64

rm -rf "$WO_DIR"
git clone --depth 1 --single-branch https://github.com/zhchmmx/warp-optip "$WO_DIR"
# 镜像里不需要一份 git 历史，安装器也不读它。
rm -rf "$WO_DIR/.git"
mkdir -p "$VENDOR_DIR"

# 解析 ViRb3/wgcf 最新 release 的版本号。releases/latest 的重定向落在 release
# 页面（/tag/vX.Y.Z），取 URL 尾段即可，不依赖 api.github.com 的匿名限速。
WO_WGCF_VER=$(curl --fail --location --silent --show-error --retry 2 --connect-timeout 10 \
    --max-time 20 \
    --output /dev/null --write-out '%{url_effective}' \
    https://github.com/ViRb3/wgcf/releases/latest |
    sed -n 's#.*/tag/v\([0-9][0-9.]*\)$#\1#p')
test -n "$WO_WGCF_VER"
echo "wgcf latest version: $WO_WGCF_VER"

# 上游 install.sh 的 vendor 搜索约定：vendor/wgcf_*_linux_<arch> 与
# vendor/warp-linux-<arch>，文件名必须和它匹配。
curl --fail --location --silent --show-error --retry 2 --connect-timeout 10 \
    --max-time 180 \
    -o "$VENDOR_DIR/wgcf_${WO_WGCF_VER}_linux_${WO_ARCH}" \
    "https://github.com/ViRb3/wgcf/releases/download/v${WO_WGCF_VER}/wgcf_${WO_WGCF_VER}_linux_${WO_ARCH}"
chmod 0755 "$VENDOR_DIR/wgcf_${WO_WGCF_VER}_linux_${WO_ARCH}"

curl --fail --location --silent --show-error --retry 2 --connect-timeout 10 \
    --max-time 180 \
    -o "$VENDOR_DIR/warp-linux-${WO_ARCH}" \
    "https://gitlab.com/Misaka-blog/warp-script/-/raw/main/files/warp-yxip/warp-linux-${WO_ARCH}"
chmod 0755 "$VENDOR_DIR/warp-linux-${WO_ARCH}"

# 冒烟测试：二进制能在这台构建机上跑起来，说明和运行时是同一个架构、文件也完
# 整。参数用上游 install.sh 探测时用的同一对（--help / -h）。
"$VENDOR_DIR/wgcf_${WO_WGCF_VER}_linux_${WO_ARCH}" --help >/dev/null
"$VENDOR_DIR/warp-linux-${WO_ARCH}" -h >/dev/null

# 烘完之后安装入口必须还在，否则 china-config 的包装脚本就是死链。
test -x "$WO_DIR/install.sh" || test -f "$WO_DIR/install.sh"
test -f "$WO_DIR/uninstall.sh"
test -f "$WO_DIR/lib/warp-optip-engine.sh"
test -f "$WO_DIR/bin/warp-optip"
