# pixel-blue-china

This repository builds a custom [bootc](https://github.com/bootc-dev/bootc) image on top of [Pixel Blue](https://github.com/zhchmmx/pixel-blue). It follows the [Universal Blue image template](https://github.com/ublue-os/image-template), which is the recommended way to make customizations to any Universal Blue image.

Currently the only modification is the Chinese input method: `ibus-rime` and `librime-lua` are installed by `build_files/build.sh`.

The resulting image is published as `ghcr.io/zhchmmx/pixel-blue-china`.

# 中文适配 (Pixel Blue China)

本镜像在 [pixel-blue](https://github.com/zhchmmx/pixel-blue)（GNOME / Fedora Silverblue 基座）之上只做两件事：预装 bootc 上装不了的输入法引擎，以及把 Flathub 指向国内镜像。

边界画在这里：**系统级默认值由镜像带，用户目录和用户偏好一概不代做。** 所以镜像不会往 `~/.config/ibus/rime` 写任何东西，也不会改你的输入源设置；词库、方案、更新时机都是你的决定。

## 中文输入法：只带引擎，配置归你

bootc 系统不能自己装系统包，用户在装机后 `dnf5 install ibus-rime` 是做不到的，所以镜像替你把这一步做掉：`ibus-rime` + `librime-lua`（后者是社区预设几乎都要、而 Fedora 不会随 `ibus-rime` 一起装的 Lua 模块）。

引擎之外还差两小步，都在你自己手里：

1. 添加输入源：设置 → 键盘 → 添加输入法 → 汉语 → Rime。等价的命令是

   ```bash
   gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'rime')]"
   ```

2. 词库与方案（可选）。不配也能直接用，Rime 自带 `luna_pinyin`、仓颉这些方案。想用雾凇拼音（[rime-ice](https://github.com/iDvel/rime-ice)），一个干净的目录可以这样起手：

   ```bash
   git clone https://github.com/iDvel/rime-ice ~/.config/ibus/rime
   ibus restart        # 或在 Rime 托盘菜单里选「部署」，首次编译词库要几十秒
   ```

   目录里已经有你在用的配置，就 clone 到别处再 `cp -a` 覆盖过去。之后更新是 `cd ~/.config/ibus/rime && git pull` 加一次重新部署；自己的改动写在 `*.custom.yaml`（patch 机制）里，上游覆盖回来不会冲掉，`*.user.xtab` 那类个人词频不在仓库里，更新也不碰。

## Flathub 国内镜像

`/etc/flatpak/remotes.d/flathub.flatpakrepo` 覆盖基座里的官方地址，默认指向上海交通大学 SJTUG 镜像（`https://mirror.sjtu.edu.cn/flathub/`），GPG 密钥与上游一致，签名校验逻辑不变。

remote 的名字仍然叫 `flathub`：GNOME 软件中心和 Discover 按这个名字识别 Flathub，改名或删掉再另加一个源，点安装时会把官方源重新建回来。

```bash
flatpak remotes -d                 # 查看当前地址
sudo flatpak remote-modify flathub --url=https://mirrors.ustc.edu.cn/flathub   # 换中科大
sudo flatpak remote-modify flathub --url=https://dl.flathub.org/repo --title=Flathub  # 换回官方
```

几点边界，来自镜像站自己的说明：SJTUG 是智能缓存，未命中会 302 回源到 Flathub 原站，所以完全不通原站时仍可能有少量请求失败；manifest 里标注 `extra-data` 的文件（NVIDIA 驱动、JetBrains 等）不经镜像站，直接从源站下载；已经装过系统的老部署，`/var/lib/flatpak` 里记录的 remote 归属不会因此改变，`bootc switch` 到本镜像后由 `/etc` 三方合并决定是否采纳新地址。

尚未提供图形化的镜像源切换入口，改源就是上面那条命令。Cloudflare WARP 与其他代理工具不在本镜像当前范围内。

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

This repository derives from `ghcr.io/zhchmmx/pixel-blue:latest`, set on the `FROM` line of the `Containerfile`. To derive from a different image instead, change that line; any Universal Blue image or a Fedora/CentOS bootc image works, for example:

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

The same file also carries the OCI and ArtifactHub metadata (`IMAGE_DESC`, `IMAGE_KEYWORDS`, `IMAGE_LOGO_URL`, `DEFAULT_TAG`, `BIB_IMAGE`), which is written into the image as labels by `just build` and stamped again after rechunking by `just ostree-rechunk`.

## Step 3: Switch to This Image

From any Pixel Blue or other bootc system, run:
```bash
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:latest
```
To stay on a specific build instead of the moving tag, use its version tag (see [Version and Tags](#version-and-tags)):
```bash
sudo bootc switch ghcr.io/zhchmmx/pixel-blue-china:20261101.42
```
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

These are all sourced from the `image-template.env` file.

- `image_name`: The name of the image (`pixel-blue-china`).
- `repo_organization`: The GitHub user or organisation the image is published under (`zhchmmx`).
- `default_tag`: The default tag for the image (default: "latest").
- `bib_image`: The Bootc Image Builder (BIB) image (default: "quay.io/centos-bootc/bootc-image-builder:latest").
- `image_desc`, `image_keywords`, `image_logo_url`: OCI and ArtifactHub metadata written as image labels.

## Version and Tags

The image version is `<UTC date>.<build number>`, for example `20261101.42`. In CI the build number is the GitHub Actions run number (`build.yml` exports `BUILD_NUMBER` and `IMAGE_VERSION`); local builds fall back to a `BUILD_NUMBER` you set yourself, then to the commit count (`git rev-list --count HEAD`). The version never carries a branch name or commit hash — the commit is recorded separately in the `org.opencontainers.image.revision` label.

`just generate-build-tags` publishes two tags: that version (a pin you can freeze a specific build to) and the moving channel tag (`latest`).

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
