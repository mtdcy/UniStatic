# UniStatic 

Prebuilt static linked libraries and binaries bundle for MacOS(Xcode) | Windows | Linux. 

This Project includes:

- [bash script](ulib.sh) functions for creating static libraries and binaries.
- prebuilt libraries & binaries 

## Build Libraries & Binaries

### Configure Your Host

#### Linux/Ubuntu

configure host with its own package manager system.

```shell
sudo apt-get install build-essential pkg-config cmake wget nasm yasm
```

#### MSYS2+MinGW64

```shell
pacman -S mingw64/mingw-w64-x86_64-toolchain
pacman -S mingw64/mingw-w64-x86_64-cmake
pacman -S mingw64/mingw-w64-x86_64-nasm
pacman -S mingw64/mingw-w64-x86_64-yasm
pacman -S wget diffutils tar openssl make
```

#### macOS+Xcode

configure your host with brew or whatever you want. 

#### Envs

 - UPKG_ROOT        - project root
 - UPKG_DLROOT      - zip download/cache folder
 - UPKG_SHARED      - build shared libs instead of static
 - UPKG_NJOBS       - number of jobs used to build
 - UPKG_TEST        - build and test

#### Variables & Functions 

 - PREFIX           - prefix for prebuilts
 - CC/CXX/...       - toolchain variables
 - upkg_configure   - function for configure source code 
 - upkg_make        - function for making source code with single job
 - upkg_make_njobs  - function for making source code with multiple jobs
 - upkg_make_test   - function for runing test suite(s)

## Libraries List

* libiconv: 1.15
* zlib: 1.2.11
* bzip2: 1.0.6
* lzma: 5.2.4
* soxr: 0.1.3
* lame: 3.100
* libogg: 1.3.3
* libvorbis: 1.3.6
* opencore-amr: 0.1.5
* opus: 1.3.1
* fdk-aac: 2.0.0
* libpng: 1.6.37
* giflib: 5.1.4
* libjpeg-turbo: 2.0.2
* libtiff: 4.0.10
* libwebp: 1.0.2
* openjpeg: 2.3.1
* libtheora: 1.1.1
* libvpx: 1.8.0
* openh264: 1.8.0
* kvazaar: 1.2.0
* x264: HEAD
* x265: 3.0
* xvidcore: 1.3.5
* frei0r: 1.6.1
* libxml2: 2.9.9

## Binaries List

* ffmepg: 4.1

## LICENSES

* This Project is licensed under BSD 2-Clause License.
* The target is either LGPL or GPL or BSD or others depends on the source code's license.

