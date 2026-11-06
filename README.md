# pixel-blue-china

This repository builds a custom [bootc](https://github.com/bootc-dev/bootc) image on top of [Pixel Blue](https://github.com/zhchmmx/pixel-blue). It follows the [Universal Blue image template](https://github.com/ublue-os/image-template), which is the recommended way to make customizations to any Universal Blue image.

Currently there are four modifications: the Chinese input method engine (`ibus-rime`, `librime-lua` and `git`, installed by `build_files/build.sh` because a bootc system cannot install system packages itself), `fuse-libs` so upstream-published `.AppImage` files still run on this image, `warp-optip` materials (the tool's scripts plus its third-party binaries, baked in at build time so `china-config warp-optip install` needs no downloads), and `china-config`, a small CLI that points Flathub at a Chinese mirror, installs the rime-ice dictionaries into your own `~/.config`, and exposes the warp-optip install/uninstall entry points. See 中文适配 below.

The resulting image is published as `ghcr.io/zhchmmx/pixel-blue-china`.

# 中文适配 (Pixel Blue China)

本镜像在 [pixel-blue](https://github.com/zhchmmx/pixel-blue)（GNOME / Fedora Silverblue 基座）之上只加两类东西：bootc 上用户自己装不出来的系统包（Rime 引擎、git、libfuse2）和烘进 `/usr` 的工具材料（warp-optip 脚本与预下载二进制），以及一个中文适配小工具 `china-config`。

边界画在这里：**镜像管 `/usr`，你的状态归你。** 用户目录、输入源设置、装没装词库、装过哪些 flatpak 应用、用哪个镜像站，镜像一概不代做，也不设默认值 —— `china-config` 提供入口，动作由你在终端里点。

## 中文输入法：镜像带引擎，装词库用 china-config

bootc 系统不能自己装系统包，所以镜像替你把引擎这一步做掉：`ibus-rime` + `librime-lua`（后者是社区预设几乎都要、而 Fedora 不会随 `ibus-rime` 一起装的 Lua 模块），外加 `git`（`china-config rime` 靠它拉词库，bootc 上事后装不上）。

引擎之外只差一步工具能做（不要加 sudo，它写的是你自己的 `~/.config`）：

```bash
china-config rime install   # 浅克隆雾凇拼音（rime-ice）到 ~/.config/ibus/rime，约 66M
```

剩下两步刻意留给你自己：在桌面里 设置 → 键盘 → 添加输入法 → 汉语 → Rime，然后 `ibus restart`（首次编译词库要几十秒）。`china-config rime status` 会报告目录、引擎、输入源三件事各是什么状态、还差哪一步；`china-config rime update` 就是 `git pull --ff-only`。

不想用工具的话，装词库等价于这一条：

```bash
git clone https://github.com/iDvel/rime-ice ~/.config/ibus/rime
```

添输入源不做成命令，是因为 `gsettings set org.gnome.desktop.input-sources sources ...` 对这个名字是**整表覆盖**，写漏一项就把手里已有的输入源冲掉了，一个装词库的命令不该担这个风险。`status` 只用 `gsettings get` 读一下当前列表，从不写入。

几条刻意的边界：目录里已经有不是 git 仓库的内容时，`install` 直接拒绝动它，要你自己备份或 `cp -a` 覆盖；`update` 认不出仓库也一样退出，不替你处理冲突。工具不内置任何第三方 GitHub 代理（拉下来的是要在你会话里跑的 Lua 代码，不经确认换源不合适），GitHub 不通就自己下载 zip 解压到 `~/.config/ibus/rime`。词库更新后的自定义改动写在 `*.custom.yaml`（patch 机制）里，上游覆盖回来不会冲掉，`*.user.xtab` 那类个人词频不在仓库里，更新也不碰。

## Flathub 源：镜像里没有默认值，改源用 china-config

镜像里 `/etc/flatpak/remotes.d/` 是空的，Flathub 指向哪儿由你自己决定一次。原因是这个镜像的用户全是 `bootc switch` 过来的，而 flatpak 对 `remotes.d` 里的定义文件只做一次「首次应用」：名字一旦进了仓库配置里的 `core.xa.applied-remotes`，那个文件之后就被无视。所以往 `/etc` 塞默认地址对切过来的机器完全空转，只会让少数全新部署看到另一个结果，两边都不是用户自己选的。详细推导在 `man china-config`。

```bash
china-config mirror status          # 看现在真正生效的地址（只读，不用 root）
china-config mirror list            # 看本工具管理的源，* 标出当前生效的
sudo china-config mirror set sjtu   # 切到上海交大 SJTUG 镜像
sudo china-config mirror set official  # 退回 Flathub 官方源
```

`status` 在当前还是官方地址时会把下一步该执行的命令直接打给你，所以切过来之后先跑一次 `status` 就够了。改完跑一次 `flatpak update`，软件中心的目录就跟着走新地址。

生效的地址写在 `/var/lib/flatpak/repo/config` 里，而 `/var` 不归镜像管，`bootc switch`、`bootc upgrade` 都碰不到它：**改一次就定下来**，不会在某次升级之后自己变回去——你之前看到的「点一下镜像源就自动改了」正是这套机制的表象。代价是每台机器都要手工执行一次 `set`。

`set` 只接受 `list` 里的别名，不接受任意 URL，所以 GPG 密钥和 collection-id 不可能被顺手改掉；构建时还会校验每个可选源用的都是 Flathub 官方那把密钥。加一个镜像 = 往 `/usr/share/china-config/remotes.d/` 放一个 `<别名>.flatpakrepo`，程序不用改，条件见 man 手册的「加一个新镜像」。

几点已知边界：SJTUG 是智能缓存，未命中会 302 回源到 Flathub 原站，完全不通原站的网络仍可能有少量请求失败；manifest 里标注 `extra-data` 的文件（NVIDIA 驱动、JetBrains 之类）不经镜像站，仍从作者提供的源站下载；USTC 的 flathub 镜像缺少 `summary.sig`（2026-11 实测 404），flatpak 拿不到可校验的目录，因此没有收进可选源。

没有图形化的切换入口：GNOME 的面板是编译进 control-center 的 C 模块，没有运行时插件位，一次性配置也不适合常驻应用网格。各类代理客户端仍然不预装；镜像在这件事上对 AppImage 只做了一件事——把跑起来所需的那个库带上，见下一节；对 Cloudflare WARP 做的是把安装材料和二进制烘进 `/usr`，装不装由你点一下决定，再下一节。

## AppImage 支持：镜像里多了一个 libfuse2

Fedora 有意把 fuse(2) 从 Atomic 桌面镜像里移掉了（ostree sig issue #50），而 AppImage 的 runtime 挂载自己时要 `libfuse.so.2`，结果就是上游发布的 `.AppImage` 在这类系统上直接起不来。

这对代理工具有实际影响：图形化管理 Clash 订阅目前只有客户端这一条路，而它们给 Linux 的形态是 deb、rpm、AppImage。前两种在这类系统上只能靠客户端 `rpm-ostree` 分层装进来，那是 bootc 下的弱路径（切镜像时不保证带过去），而且 FlClash 的包会把主体塞进 `/opt` —— 本镜像的 `/opt` 还是指向可写 `/var/opt` 的符号链接，bootc 部署时那里的内容可能被清掉。**AppImage 是唯一一个不用改镜像、跑起来的又正好是上游那一个可校验产物的形态**。把 AppImage 解包再拼起来跑，运行对象就成了我们自己组装的东西，校验和更新都更差。所以这里补一个库，而不是让用户改用法。

边界照旧：**镜像没有装任何代理客户端，没有代理内核，没有服务**，只多了 `fuse-libs` 这一个包（WARP 的材料是另一回事，见下一节——那也是材料，不是装好的状态）。AppImage 跑起来之后要不要开 TUN、订阅给谁、节点怎么选，全是用户自己的决定。

这是个逆着上游方向的取舍（libfuse2 是老代码基，一些 Atomic 衍生镜像出于安全考虑明确不带它），所以构建里直接断言 `/usr/lib64/libfuse.so.2` 存在：Fedora 现在已经另有一个独立的 `fuse2` 源码包，将来提供者的名字变了就构建失败，而不是静默产出一个跑不了 AppImage 的镜像。

不认同这个取舍的话回退很容易：`rpm-ostree override remove fuse-libs` 之后，AppImage 还能用 `APPIMAGE_EXTRACT_AND_RUN=1 ./FlClash.AppImage` 跑，不需要 FUSE，代价是每次启动都要解压一遍。反过来说，只在机器上 `rpm-ostree install fuse-libs` 分层不是好办法——bootc 下客户端分层是弱路径，切镜像时不保证带过去，所以这个包放在镜像里比放在机器上更稳。

## Cloudflare WARP：镜像烘好材料和二进制，装不装用 china-config 点

[warp-optip](https://github.com/zhchmmx/warp-optip) 是 WARP endpoint 自动优选工具（NetworkManager 原生 WireGuard，pre-up 阶段扫描换 endpoint）。构建时把它的最新 main 克隆进 `/usr/libexec/warp-optip/`，并把安装所需的两个第三方二进制提前下好放进 `vendor/`：wgcf 取 GitHub 最新 release，warp 扫描器来自 Misaka-blog/warp-script，都是 amd64（本镜像只适配 Pixel 6，不为其他架构出产物）。装的时候不联网下载任何东西，这一步走 `--no-download`；首次安装要注册 wgcf 账号，那一步得能访问 Cloudflare API，和下载无关。

```bash
sudo china-config warp-optip install      # 上游 install.sh，二进制用镜像里预下载的
sudo china-config warp-optip uninstall    # 上游 uninstall.sh，可加 --purge
```

包装脚本只做一件事：不带参数直接跑时，默认注入 `--no-download` 和 `--wgcf-bin` / `--warp-bin`（指到 vendor/ 的预下载二进制）；这三个选项你手动传了任何一个，该项就以你传的为准，其余参数一律原样透传。root、`nmcli`、`wg` 这些检查都由上游脚本自己做、报自己的错，china-config 不重复设门槛，也不另设 status 子命令（装好之后 `sudo warp-optip status` 看状态）。

装出去的东西全在可变层：程序进 `/usr/local`（bootc 上即可写的 `/var/usrlocal`），配置进 `/etc/warp-optip.conf`，账号和状态进 `/var/lib/warp-optip/`，NetworkManager 默认新建一个独立的 `warp-optip` 连接、不动现有 `wgcf-profile`——`bootc upgrade` 都碰不到它们。激活与否也归你：`nmcli connection up warp-optip`。

这个镜像只适配 Pixel 6 这一款设备，所以构建里不做架构自适应、不装 wireguard-tools（`wg` 在基座里按存在算），上游仓库也跟随最新版本不 pin：接口对不上会在全新构建的冒烟测试里直接失败，不会静默产出坏镜像；某个已发布镜像里烘的是哪个提交，看那次构建的日志。

# Testing channel (测试通道)

两条分支的内容**完全相同**，通道由分支名决定，映射只写在 `channel.sh` 一处（`just` 用它算 `default_tag`，`Containerfile` 把同一个值当 `BASE_TAG` 收下）：

| 分支 | 基础镜像 | 发布为 |
| --- | --- | --- |
| `main` | `ghcr.io/zhchmmx/pixel-blue:latest` | `ghcr.io/zhchmmx/pixel-blue-china:latest` |
| `testing` | `ghcr.io/zhchmmx/pixel-blue:testing` | `ghcr.io/zhchmmx/pixel-blue-china:testing` |

`pixel-blue-china:testing` 就是「Pixel Blue 的测试版 + 本仓库的中文适配」，所以还没进上游 `latest` 的改动可以在中文环境里先试：

```bash
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:testing   # 试上游测试版
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:latest    # 切回稳定版
```

触发条件是 `testing` 分支有推送，或者在 Actions 里选 `testing` 分支手动 Run workflow —— 上游自己的 testing 构建不会自动触发这里；想把上游新烘进去的内容拉进来，推一次 `testing` 或手动跑一次即可。两条通道互不覆盖：`latest` 只由 `main` 发布，`testing` 只由 `testing` 发布，PR 只构建、不推送也不签名；推到其他分支不会有事，因为 `channel.sh` 在 CI 里认不出分支就直接失败，误 dispatch 顶不掉 `latest`。

分支内容相同意味着把 `testing` 追平 `main` 不产生任何文件差异（`git merge main`）：通道差异全在分支名里，不在代码里。

# Community

If you have questions about this template after following the instructions, try the following spaces:
- [Universal Blue Forums](https://universal-blue.discourse.group/)
- [Universal Blue Discord](https://discord.gg/8RZGC3uFzA)
- [bootc discussion forums](https://github.com/bootc-dev/bootc/discussions) - This is not an Universal Blue managed space, but is an excellent resource if you run into issues with building bootc images.

# How to Use

If you just want to run this image, skip to [Step 3: Switch to This Image](#step-3-switch-to-this-image). The steps before it describe how to build the image yourself, either from a fork of this repository or from the upstream template.

If you prefer instructions in video form, TesterTech created an excellent tutorial on the upstream template, embedded below.

[![Video Tutorial](https://img.youtube.com/vi/IxBl11Zmq5w/0.jpg)](https://www.youtube.com/watch?v=IxBl11Zmq5wE)

## Step 0: Prerequisites

These steps assume you have the following:
- A Github Account
- A machine running a bootc image (e.g. Pixel Blue, Bazzite, Bluefin, Aurora, or Fedora Atomic)
- Experience installing and using CLI programs

## Step 1: Preparing the Repository

### Step 1a: Getting a Copy

To build your own variant, fork this repository, or start from the upstream [image template](https://github.com/ublue-os/image-template) and set the name and description to whatever you would like.

Once you have finished copying, you need to enable the Github Actions workflows for your new repository.
To enable the workflows, go to the `Actions` tab of the new repository and click the button to enable workflows.

### Step 1b: Cloning the Repository

Here I will defer to the much superior GitHub documentation on the matter. You can use whichever method is easiest.
[GitHub Documentation](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository)

Once you have the repository on your local drive, proceed to the next step.

## Step 2: Initial Setup

### Step 2a: Creating a Cosign Key

Container signing is important for end-user security and is enabled on all Universal Blue images. By default the image builds *will fail* if you don't.

First, install the [cosign CLI tool](https://edu.chainguard.dev/open-source/sigstore/cosign/how-to-install-cosign/#installing-cosign-with-the-cosign-binary)
With the cosign tool installed, run inside your repo folder:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

The signing key will be used in GitHub Actions and will not work if it is password protected.

> [!WARNING]
> Be careful to *never* accidentally commit `cosign.key` into your git repo. If this key goes out to the public, the security of your repository is compromised.

Next, you need to add the key to GitHub. This makes use of GitHub's secret signing system.

<details>
    <summary>Using the Github Web Interface (preferred)</summary>

Go to your repository settings, under `Secrets and Variables` -> `Actions`
![image](https://user-images.githubusercontent.com/1264109/216735595-0ecf1b66-b9ee-439e-87d7-c8cc43c2110a.png)
Add a new secret and name it `SIGNING_SECRET`, then paste the contents of `cosign.key` into the secret and save it. Make sure it's the .key file and not the .pub file. Once done, it should look like this:
![image](https://user-images.githubusercontent.com/1264109/216735690-2d19271f-cee2-45ac-a039-23e6a4c16b34.png)
</details>
<details>
<summary>Using the Github CLI</summary>

If you have the `github-cli` installed, run:

```bash
gh secret set SIGNING_SECRET < cosign.key
```
</details>

### Step 2b: Base Image

This repository derives from `ghcr.io/zhchmmx/pixel-blue`, with the tag coming from the branch: `main` builds on `:latest` and the `testing` branch on `:testing`. The tag is resolved by `channel.sh` and passed to the `FROM` line of the `Containerfile` as the `BASE_TAG` build argument, so both branches carry identical files (see [Testing channel](#testing-channel-测试通道)). To derive from a different image instead, change that `FROM` line; any Universal Blue image or a Fedora/CentOS bootc image works, for example:

<details>
    <summary>Base Images</summary>

- Pixel Blue: `ghcr.io/zhchmmx/pixel-blue:latest`
- Bazzite: `ghcr.io/ublue-os/bazzite:stable`
- Aurora: `ghcr.io/ublue-os/aurora:stable`
- Bluefin: `ghcr.io/ublue-os/bluefin:stable`
- Universal Blue Base: `ghcr.io/ublue-os/base-main:latest`
- Fedora: `quay.io/fedora/fedora-bootc:44`

You can find more Universal Blue images on the [packages page](https://github.com/orgs/ublue-os/packages).
</details>

If you don't know which image to pick, choosing the one your system is currently on is the best bet for a smooth transition. To find out what image your system currently uses, run the following command:
```bash
sudo bootc status
```
This will show you all the info you need to know about your current image. The image you are currently on is displayed after `Booted image:`. Paste that information after the `FROM` statement in the Containerfile to set it as your base image.

### Step 2c: Names

The names are already set in `image-template.env`: `IMAGE_NAME=pixel-blue-china` and `REPO_ORGANIZATION="zhchmmx"`.

`IMAGE_NAME` must keep matching the GitHub repository name: `build.yml` pushes the image named in `image-template.env`, while `build-disk.yml` pulls `${{ github.event.repository.name }}`, so renaming one without the other breaks the disk build.

The same file also carries the OCI and ArtifactHub metadata (`IMAGE_DESC`, `IMAGE_KEYWORDS`, `IMAGE_LOGO_URL`, `BIB_IMAGE`), which is written into the image as labels by `just build` and stamped again after rechunking by `just ostree-rechunk`. It deliberately carries no tag: the channel comes from the branch, see [Testing channel](#testing-channel-测试通道).

## Step 3: Switch to This Image

From any Pixel Blue or other bootc system, run:
```bash
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:latest
```
To stay on a specific build instead of the moving tag, use its version tag (see [Version and Tags](#version-and-tags)):
```bash
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:20261101.42
```
To try the upstream testing channel on top of the same Chinese adaptations, switch to `:testing` instead (see [Testing channel](#testing-channel-测试通道)).
This should queue your image for the next reboot, which you can do immediately after the command finishes. See the following section for an explanation of the important parts of the template for customization.

# Repository Contents

## Containerfile

The [Containerfile](./Containerfile) defines the operations used to customize the selected image.This file is the entrypoint for your image build, and works exactly like a regular podman Containerfile. For reference, please see the [Podman Documentation](https://docs.podman.io/en/latest/Introduction.html).

## build.sh

The [build.sh](./build_files/build.sh) file is called from your Containerfile. It is the best place to install new packages or make any other customization to your system. There are customization examples contained within it for your perusal.

## build.yml

The [build.yml](./.github/workflows/build.yml) Github Actions workflow creates your custom OCI image and publishes it to the Github Container Registry (GHCR). By default, the image name will match the Github repository name.

# Building Disk Images

This repository builds qcow2 disk images from the OCI image, which can be installed directly onto a machine or imported into a hypervisor. ISO images are not built here.

The workflow provides a way to upload the generated disk image to an S3 bucket. If you do not use S3, the disk image is available as an artifact from the job. To upload to S3 we use [rclone](https://rclone.org/), which is able to use [many S3 providers](https://rclone.org/s3/).

## Setting Up Disk Builds

The [build-disk.yml](./.github/workflows/build-disk.yml) Github Actions workflow creates the disk image from the OCI image produced by `build.yml`, by utilizing the [bootc-image-builder](https://osbuild.org/docs/bootc/). It runs on `workflow_dispatch` (choose `amd64` or `arm64`), and on pull requests that touch `disk_config/disk.toml` or the workflow itself. To use it:

1. Adjust `disk_config/disk.toml` if you need different filesystem customizations; the default sets a 20 GiB minimum for `/`.
2. `IMAGE_NAME` in `build-disk.yml` comes from the repository name and must keep matching `IMAGE_NAME` in `image-template.env` (see Step 2c). If you change either, change both.
3. If you want to upload your disk images to S3, add your S3 configuration to the repository's Action secrets. This can be found by going to your repository settings, under `Secrets and Variables` -> `Actions`. You will need to add the following
  - `S3_PROVIDER` - Must match one of the values from the [supported list](https://rclone.org/s3/)
  - `S3_BUCKET_NAME` - Your unique bucket name
  - `S3_ACCESS_KEY_ID` - It is recommended that you make a separate key just for this workflow
  - `S3_SECRET_ACCESS_KEY` - See above.
  - `S3_REGION` - The region your bucket lives in. If you do not know then set this value to `auto`.
  - `S3_ENDPOINT` - This value will be specific to the bucket as well.

Once the workflow is done, you'll find the disk image either in your S3 bucket or as part of the summary under `Artifacts` after the workflow is completed.

# Artifacthub

This template comes with the necessary tooling to index your image on [artifacthub.io](https://artifacthub.io). Use the `artifacthub-repo.yml` file at the root to verify yourself as the publisher. This is important to you for a few reasons:

- The value of artifacthub is it's one place for people to index their custom images, and since we depend on each other to learn, it helps grow the community. 
- You get to see your pet project listed with the other cool projects in Cloud Native.
- Since the site puts your README front and center, it's a good way to learn how to write a good README, learn some marketing, finding your audience, etc. 

[Discussion Thread](https://universal-blue.discourse.group/t/listing-your-custom-image-on-artifacthub/6446)

# Justfile Documentation

The `Justfile` contains various commands and configurations for building and managing container images and virtual machine images using Podman and other utilities. It is also used inside Github Actions.

## Required Utilities

Container build:
- [just](https://just.systems/man/en/introduction.html)
- [podman](https://docs.podman.io/en/latest)
- [jq](https://jqlang.org)

These are usually preinstalled on Universal Blue's Bootc Images.

Linting:
- shfmt
- shellcheck

## Environment Variables

These are all sourced from the `image-template.env` file, except `default_tag`, which is derived from the branch.

- `image_name`: The name of the image (`pixel-blue-china`).
- `repo_organization`: The GitHub user or organisation the image is published under (`zhchmmx`).
- `default_tag`: The channel of the current branch (`latest` on `main`, `testing` on the `testing` branch), resolved from the branch by `channel.sh` rather than set in this file.
- `bib_image`: The Bootc Image Builder (BIB) image (default: "quay.io/centos-bootc/bootc-image-builder:latest").
- `image_desc`, `image_keywords`, `image_logo_url`: OCI and ArtifactHub metadata written as image labels.

## Version and Tags

The image version is `<UTC date>.<build number>`, for example `20261101.42`. In CI the build number is the GitHub Actions run number (`build.yml` exports `BUILD_NUMBER` and `IMAGE_VERSION`); local builds fall back to a `BUILD_NUMBER` you set yourself, then to the commit count (`git rev-list --count HEAD`). The version never carries a branch name or commit hash — the commit is recorded separately in the `org.opencontainers.image.revision` label.

`just generate-build-tags` publishes two tags: that version (a pin you can freeze a specific build to) and the moving channel tag of the branch (`latest` on `main`, `testing` on the `testing` branch).

Both `just build` and `just ostree-rechunk` write the labels, because `rpm-ostree compose build-chunked-oci` re-exports the image without the config labels it was built with; without the second stamp the pushed image would arrive at GHCR with no metadata at all.

## Building The Image

All these recipes will work (with default values) without supplying any arguments to them, e.g. `just build`

### `just build`

Builds a container image using Podman.

```bash
just build $target_image $tag
```

Arguments:
- `$target_image`: The tag you want to apply to the image (default: `$image_name`).
- `$tag`: The tag for the image (default: `$default_tag`).

### Rechunking
We can flatten the layers of container images to make sure there isn't a single huge layer when your image gets published.
This does not make your image faster to download, just provides better resumability.

#### `just ostree-rechunk`
Rechunks the existing Image with [rpm-ostree](https://coreos.github.io/rpm-ostree/build-chunked-oci/)

```bash
just ostree-rechunk $target_image $tag
```

#### `just rechunk`
Rechunks the existing Image with [chunkah](https://github.com/coreos/chunkah), this is probably gonna be the default here at some point, try it out, it's cool.

```bash
just rechunk $target_image $tag
```

### Switching to the locally built image for testing

The image has to be in the containers-storage owned by root, to be able to rebase to it, see the `_rootful_load_image` recipe.

`sudo just build` and `sudo just ostree-rechunk` builds directly as root and allows you to skip the transfer to the root containers-storage.

You can rebase to all the images that are in your containers-storage:

```
sudo podman image list --filter=label=containers.bootc=1
```

See [man bootc switch](https://bootc.dev/bootc/man/bootc-switch.8.html) for more info.

```
sudo bootc switch --transport containers-storage localhost/myimage:latest
```

and reboot your system!

## Building and Running Virtual Machines

The below commands all build QCOW2 images. To produce or use a different type of image, substitute in the command with that type in the place of `qcow2`. The available types are `qcow2` and `raw`. ISO images are not built by this repository.

### `just build-qcow2`

Builds a QCOW2 virtual machine image.

```bash
just build-qcow2 $target_image $tag
```

### `just rebuild-qcow2`

Rebuilds a QCOW2 virtual machine image.

```bash
just rebuild-vm $target_image $tag
```

### `just run-vm-qcow2`

Runs a virtual machine from a QCOW2 image.

```bash
just run-vm-qcow2 $target_image $tag
```

### `just spawn-vm`

Runs a virtual machine using systemd-vmspawn.

```bash
just spawn-vm rebuild="0" type="qcow2" ram="6G"
```

## File Management

### `just check`

Checks the syntax of all `.just` files and the `Justfile`.

### `just fix`

Fixes the syntax of all `.just` files and the `Justfile`.

### `just clean`

Cleans the repository by removing build artifacts.

### `just lint`

Runs shell check on all Bash scripts.

### `just format`

Runs shfmt on all Bash scripts.

## Additional resources

For additional driver support, ublue maintains a set of scripts and container images available at [ublue-akmod](https://github.com/ublue-os/akmods). These images include the necessary scripts to install multiple kernel drivers within the container (Nvidia, OpenRazer, Framework...). The documentation provides guidance on how to properly integrate these drivers into your container image.

## Community Examples

These are images derived from this template (or similar enough to this template). Reference them when building your image!

- [m2Giles' OS](https://github.com/m2giles/m2os)
- [bOS](https://github.com/bsherman/bos)
- [Homer](https://github.com/bketelsen/homer/)
- [Amy OS](https://github.com/astrovm/amyos)
- [VeneOS](https://github.com/Venefilyn/veneos)
