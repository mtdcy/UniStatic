SHELL := /bin/bash

all: ALL

.PHONY: all

##############################################################################
define TEMPLATE
# shellcheck disable=SC2034

#1. build with docker
export DOCKER_IMAGE=

#2. build with remote host
export REMOTE_HOST=

# packages cache
export PACKAGES=./packages

# pass through envs
export UPKG_STRICT=1
export UPKG_NJOBS=4
export ULOG_MODE=tty

# distcc
export DISTCC_VERBOSE=0
export DISTCC_HOSTS=""
export DISTCC_OPTS=

# install dest
export HOST=
export DEST=
endef
export TEMPLATE

cmdlets.env:
	@echo "$$TEMPLATE" > $@
	@echo "== Please edit $@ first, then"
	@echo "    source $@"
	@echo "    make prepare-host-homebrew"
	@echo "OR  make prepare-host-debian"
	@echo "OR  make prepare-docker-image"
	@echo "OR  make prepare-remote-homebrew"
	@echo "OR  make prepare-remote-debian"
	@echo ""
	@echo "    make zlib"

##############################################################################
# commands run in remote host or docker
CMD ?=

# pass throught envs to build.sh on remote or docker
ENVs = UPKG_NJOBS=$(UPKG_NJOBS)   \
	   ULOG_MODE=$(ULOG_MODE)     \
	   UPKG_STRICT=$(UPKG_STRICT)

# contants: use '-acz' for remote without time sync.
REMOTE_SYNC = rsync -e 'ssh' -a --exclude='.*'

# no distcc settings pass through to remote
REMOTE_EXEC = ssh $(REMOTE_HOST) -tq TERM=xterm

ifneq ($(DOCKER_IMAGE),)
ifeq ($(ULOG_MODE),tty)
DOCKER_EXEC = docker run --rm -it                   \
			  -u $(USER):$(GROUP)                   \
			  -v $(WORKDIR):$(WORKDIR)              \
			  -v $(PACKAGES):$(WORKDIR)/packages    \
			  -e DISTCC_VERBOSE="$(DISTCC_VERBOSE)" \
			  -e DISTCC_HOSTS="$(DISTCC_HOSTS)"     \
			  -e DISTCC_OPTS="$(DISTCC_OPTS)"       \
			  --name $(DOCKER_IMAGE)                \
			  $(DOCKER_IMAGE) bash -li -c
else
DOCKER_EXEC = docker run --rm                       \
			  -u $(USER):$(GROUP)                   \
			  -v $(WORKDIR):$(WORKDIR)              \
			  -v $(PACKAGES):$(WORKDIR)/packages    \
			  -e DISTCC_VERBOSE="$(DISTCC_VERBOSE)" \
			  -e DISTCC_HOSTS="$(DISTCC_HOSTS)"     \
			  -e DISTCC_OPTS="$(DISTCC_OPTS)"       \
			  --name $(DOCKER_IMAGE)                \
			  $(DOCKER_IMAGE) bash -l -c
endif
endif

# wired: '$(shell test -t 1)' report wrong state
test-tty:
	@echo "#0 $(shell test -t 0 && echo "with tty" || echo "without tty")"
	@echo "#1 $(shell test -t 1 && echo "with tty" || echo "without tty")"
	@echo "#2 $(shell test -t 2 && echo "with tty" || echo "without tty")"
	@./test-tty.sh

# internal variables
USER  	= $(shell id -u)
GROUP 	= $(shell id -g)
ARCH  	= $(shell gcc -dumpmachine | sed 's/[0-9\.]\+$$//;s/-alpine//')
WORKDIR = $(shell pwd)

##############################################################################
# Build Binaries & Libraries

vpath %.u libs

# Example:
#  	#1. REMOTE_HOST=10.10.10.234 make zlib
# 	#2. DOCKER_IMAGE=cmdlets make zlib
%: %.u
ifneq ($(REMOTE_HOST),)
	make exec-remote CMD="make $@" # replay cmd in remote
else ifneq ($(DOCKER_IMAGE),)
	make exec-docker CMD="make $@" # replay cmd in docker
else
	$(ENVs) ./build.sh $@
endif

clean:
ifneq ($(REMOTE_HOST),)
	make exec-remote CMD="make $@"
else
	$(ENVs) rm -rf out
endif

distclean: clean
ifneq ($(REMOTE_HOST),)
	make exec-remote CMD="make $@"
else ifneq ($(DOCKER_IMAGE),)
	make exec-docker CMD="make $@"
else
	$(ENVs) rm -rf prebuilts/$(ARCH)
endif

shell:
ifneq ($(REMOTE_HOST),)
	make exec-remote CMD="make $@"
else ifneq ($(DOCKER_IMAGE),)
	make exec-docker CMD="make $@"
else
	$(ENVs) exec $$SHELL -li
endif

.PHONY: clean distclean shell

##############################################################################
# prepare remote & docker

# sync time between host and docker
#  => don't use /etc/timezone, as timedatectl won't update this file
TIMEZONE = $(shell realpath --relative-to /usr/share/zoneinfo /etc/localtime)

BREW_PACKAGES 	= wget curl git                                    \
				  gnu-tar xz lzip unzip                            \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex                             \
				  luajit perl

DEB_PACKAGES 	= wget curl git                                    \
				  xz-utils lzip unzip                              \
				  build-essential                                  \
				  automake autoconf libtool pkg-config cmake meson \
				  nasm yasm bison flex                             \
				  luajit perl libhttp-daemon-perl                  \

prepare-host-homebrew:
	brew install $(BREW_PACKAGES)

prepare-host-debian:
	sudo apt install -y $(DEB_PACKAGES)

prepare-remote:
	test -f ~/.ssh/id_rsa || ssh-keygen
	ssh-copy-id $(REMOTE_HOST)

# Please install 'Command Line Tools' first
#  => start a login shell to invoke brew prefixes
prepare-remote-homebrew: prepare-remote
	$(REMOTE_EXEC) '$$SHELL -li -c "brew install $(BREW_PACKAGES)"'

prepare-remote-debian: prepare-remote
	$(REMOTE_EXEC) 'sudo apt install -y $(DEB_PACKAGES)'

# TODO
prepare-remote-msys2:
	$(REMOTE_EXEC)

prepare-docker-image:
	docker build                                  	\
		-t $(DOCKER_IMAGE)                        	\
		--build-arg LANG=${LANG}                  	\
		--build-arg TZ=$(TIMEZONE)                	\
		--build-arg MIRROR=http://mirrors.mtdcy.top \
		.

prepare-docker-image-alpine:
	docker build -f Dockerfile.alpine  			  	\
		-t $(DOCKER_IMAGE)                        	\
		--build-arg LANG=${LANG}                  	\
		--build-arg TZ=$(TIMEZONE)                	\
		--build-arg MIRROR=http://mirrors.mtdcy.top \
		.

##############################################################################
# remote:
# 	#1. rsync with ssh is the best way, no extra utils or services is needed.
# 	#2. using default $SHELL instead of bash, as remote may set PATH for default login shell only.
# 	#3. always request a TTY => https://community.hpe.com/t5/operating-system-linux/sshmake-session-quot-tput-no-value-for-term-and-no-t-specified/td-p/5255040
push-remote:
	@bash ulib.sh ulog info "@Push" "$(WORKDIR) => $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	@$(REMOTE_SYNC) --exclude='packages' --exclude='prebuilts' --exclude='out' $(WORKDIR)/ $(REMOTE_HOST):$(REMOTE_WORKDIR)/

pull-remote:
	@bash ulib.sh ulog info "@Pull" "$(REMOTE_HOST):$(REMOTE_WORKDIR) => $(WORKDIR)"
	@$(REMOTE_SYNC) --exclude='$(ARCH)' $(REMOTE_HOST):$(REMOTE_WORKDIR)/prebuilts/ $(WORKDIR)/prebuilts/

exec-remote: push-remote
	@bash ulib.sh ulog info "SHELL" "$(CMD) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_EXEC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && $(ENVs) $(CMD)"'
	@make pull-remote
	@bash ulib.sh ulog info "@END@" "Leaving $(REMOTE_HOST):$(REMOTE_WORKDIR)"

##############################################################################
# docker
exec-docker:
	@bash ulib.sh ulog info "SHELL" "$(CMD) @ docker ($(DOCKER_IMAGE))"
	$(DOCKER_EXEC) 'cd $(WORKDIR) && $(ENVs) $(CMD)'
	@bash ulib.sh ulog info "@END@" "Leaving $(DOCKER_IMAGE)"

# TODO
exec-remote-docker:

##############################################################################
# Install prebuilts @ Host
PREBUILTS = $(wildcard prebuilts/*)

# always update by checksum
install: $(PREBUILTS)
ifeq ($(HOST),)
	rsync -avc prebuilts/ $(DEST)/prebuilts/
else
	rsync -avcz prebuilts/ $(HOST):$(DEST)/prebuilts/
endif

.PHONY: install
.NOTPARALLEL: all

# vim:ft=make:ff=unix:fenc=utf-8:noet:sw=4:sts=0
