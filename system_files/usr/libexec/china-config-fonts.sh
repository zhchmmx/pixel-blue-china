#!/bin/sh
#
# 把这台机器上的中文字体复制到当前用户的用户字体目录。
#
# 由 china-config-fonts.service 在每次用户会话启动时调用。它不是给人跑的命
# 令，所以放在 /usr/libexec/、不接参数、不打印进度；正常情况下它的产出就是
# 目标目录里那几个字体文件本身。
#
# 为什么需要它：Flatpak 沙盒里的 fontconfig 会认定宿主机字体缓存「已经是新
# 的」而跳过真实扫描（/run/host/fonts 下看得见目录、看不见字体），于是中文
# 应用里的汉字全是方框。~/.local/share/fonts 走的是另一条通道
# （/run/host/user-fonts），不经过那个判断。现象、复现和上游跟踪见
# https://github.com/zhchmmx/pixel-blue-china/issues/6 和
# https://github.com/flatpak/flatpak/issues/6738 。
#
# 复制而不是符号链接：沙盒里链到宿主机字体目录的目标不存在。

set -eu

# 以 root 运行会把文件复制进 /root 并留下 root 属主，之后沙盒读不到、用户也
# 删不掉。systemd --user 正常不会以 root 起这个，兜底而已。
if [ "$(id -u)" -eq 0 ]; then
  exit 0
fi

target="${XDG_DATA_HOME:-${HOME}/.local/share}/fonts"

# 复制哪些字体：问 fontconfig，不猜包名也不猜目录名。这台机器上的 CJK 字体
# 可能来自镜像自带的包、装机时按语言拉进来的 langpack，或者用户自己装的其他
# 字库，只有 fc-list 的结果对眼前这台机器是准的。用 --format 是因为「fc-list
# :lang=zh file」会在每行尾多一个「: 」；同一个 ttc 会因为多个 face 重复出
# 现，所以 sort -u。
sources=$(fc-list --format='%{file}\n' :lang=zh 2>/dev/null |
  grep -Ei '\.(ttc|otf|ttf)$' |
  sort -u) || true

# 一条都没有就直接走人，连目标目录都不建：那台机器上根本没有中文字体可复制，
# 是镜像或装机语言的问题，不该由这个服务留一个空目录当线索。
[ -n "${sources}" ] || exit 0

mkdir -p "${target}"

copied=0
while IFS= read -r src; do
  [ -f "${src}" ] || continue
  dest="${target}/$(basename "${src}")"
  # 只在目标不存在、或者宿主机那份更新时才动手。这样第二次登录基本什么都不
  # 做，字体包升级之后它自己会跟进，不需要另外记状态。「源比目标新」用
  # find -newer 判断而不是 [ -nt ]：后者是 bash 扩展，这里声明的是 sh。
  if [ -e "${dest}" ] && [ -z "$(find "${src}" -newer "${dest}" 2>/dev/null)" ]; then
    continue
  fi
  # 先落成 .tmp 再改名：中途被打断不会留下半个 ttc 让 fontconfig 去解析。
  cp -p "${src}" "${dest}.tmp"
  mv -f "${dest}.tmp" "${dest}"
  copied=$((copied + 1))
done <<EOF
${sources}
EOF

# 只在真复制了东西时才刷缓存。fc-cache 要把每个 ttc 重新解析一遍，Noto CJK
# 那种集合字体一个文件就是上百兆，每次登录都刷会给会话启动白加几秒。
if [ "${copied}" -ne 0 ]; then
  fc-cache -fv "${target}"
fi

exit 0
