# UniStatic 

Prebuilt single file, pseudo-static binaries and libraries for Linux | macOS | Windows.

This Project includes:

- [bash script](ulib.sh) functions for creating static libraries and binaries.

## Quick Start 

```shell
# Github
curl https://raw.githubusercontent.com/mtdcy/UniStatic/main/cmdlets.sh -o cmdlets.sh
# CN
curl https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlets.sh -o cmdlets.sh 

# Install cmdlet
cmdlets.sh install ffmpeg
# OR
ln -svf cmdlets.sh ffmpeg

# Update cmdlet
cmdlets.sh update ffmpeg

# Update self
cmdlets.sh upgrade
```

## Binaries

- x86_64-linux-gnu      - [bin](https://pub.mtdcy.top:8443/UniStatic/current/prebuilts/x86_64-linux-gnu/bin/)
- x86_64-apple-darwin   - [bin](https://pub.mtdcy.top:8443/UniStatic/current/prebuilts/x86_64-apple-darwin/bin/)

## Libraries

- x86_64-linux-gnu      - [packages.lst](https://pub.mtdcy.top:8443/UniStatic/current/prebuilts/x86_64-linux-gnu/packages.lst)
- x86_64-apple-darwin   - [packages.lst](https://pub.mtdcy.top:8443/UniStatic/current/prebuilts/x86_64-apple-darwin/packages.lst)

## Build Libraries & Binaries

### Configure Your Host

- Linux     - see the [Dockerfile](Dockerfile) for details.
- macOS     - see [Makefile](Makefile) `make prepare-remote-homebrew`
- MSYS2     - TODO

### Build on Host

```shell
export UPKG_DLROOT=/path/to/package/cache # [optional]
export UPKG_NJOBS=8 # [optional]
./build.sh zlib
# OR
make zlib
```

### Build with Docker

```shell
export DOCKER_IMAGE=unistatic
make prepare-docker-image       # run only once
make zlib
```

### Build with remote machine

```shell
export REMOTE_HOST=10.10.10.234
make prepare-remote-homebrew    # run only once
make zlib
```

## LICENSES

* This Project is licensed under BSD 2-Clause License.
* The target is either LGPL or GPL or BSD or others depends on the source code's license.

