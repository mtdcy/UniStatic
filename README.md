# UniStatic 

Prebuilt single file, pseudo-static binaries and libraries for Linux | macOS | Windows.

This Project includes:

- [bash script](ulib.sh) functions for creating static libraries and binaries.

## Quick Start 

```shell
# Github
wget https://raw.githubusercontent.com/mtdcy/UniStatic/main/cmdlet.sh -O cmdlet.sh
# CN
wget https://git.mtdcy.top:8443/mtdcy/UniStatic/raw/branch/main/cmdlet.sh -O cmdlet.sh 

# Create symlink
ln -svf cmdlet.sh ffmpeg

# Download the prebuilt ffmpeg on first run
./ffmpeg -h
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

#### Envs

- UPKG_ROOT        - project root, default: $PWD
- UPKG_DLROOT      - zip download/cache folder
- UPKG_NJOBS       - number of jobs used to build
- UPKG_TEST        - build and test

#### Variables & Functions

- PREFIX           - prefix for prebuilts
- CC/CXX/...       - toolchain variables
- upkg_configure   - function for configure source code
- upkg_make        - function for making source code with single job
- upkg_make_njobs  - function for making source code with multiple jobs
- upkg_make_test   - function for runing test suite(s)

## LICENSES

* This Project is licensed under BSD 2-Clause License.
* The target is either LGPL or GPL or BSD or others depends on the source code's license.

