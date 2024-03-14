# SSH environment

## macOS/zsh

see [Makefile](Makefile)

`$$SHELL -l` ==> put your `PATH` in .zprofile.

otherwise, use `$$SHELL -li`, which cause powerlevel10k failed.

# Docker environment 

see [Dockerfile](Dockerfile)

run `make prepare-docker-image` to prepare docker image first.
