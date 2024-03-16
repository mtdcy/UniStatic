all: ALL

.PHONY: all

LIBS 	?=

# commands run in remote host or docker
CMD 	?=

# publish prebuilts to HOST:DEST
HOST 	?=
DEST 	?= /mnt/Service/Downloads/public/UniStatic/current

# remote host and work dir
REMOTE_HOST 	?=
REMOTE_WORKDIR 	?= ~/UniStatic

# docker image (only when remote is not set)
ifeq ($(REMOTE_HOST),)
DOCKER_IMAGE 	?=
endif

# package cache dir
#  remote: UNSUPPORTED, set manually
#  docker: volume mount
PACKAGES ?= /mnt/Service/Caches/packages

# make njobs
UPKG_NJOBS ?= 8

# mode (ulog): 'test -t' does not reflect the real situation in docker or remote.
# 	=> 'docker run -it' or 'bash -li' will affect the test.
# 	=> @see test-tty, 'test -t 1' report wrong state in Makefile.
ULOG_MODE ?= tty

# ENVs: pass to docker or remote
ENVs = UPKG_NJOBS=$(UPKG_NJOBS)   \
	   ULOG_MODE=$(ULOG_MODE)     \
	   UPKG_STRICT=$(UPKG_STRICT)

# contants: use '-acz' for remote without time sync.
REMOTE_SYNC = rsync -e 'ssh' -a --exclude='.*'

REMOTE_EXEC = ssh $(REMOTE_HOST) -tq -o "BatchMode yes" TERM=xterm

ifneq ($(DOCKER_IMAGE),)
ifeq ($(ULOG_MODE),tty)
DOCKER_EXEC = docker run --rm -it                \
			  -u $(USER):$(GROUP)                \
			  -v $(WORKDIR):$(WORKDIR)           \
			  -v $(PACKAGES):$(WORKDIR)/packages \
			  $(DOCKER_IMAGE) bash -li -c
else
DOCKER_EXEC = docker run --rm                    \
			  -u $(USER):$(GROUP)                \
			  -v $(WORKDIR):$(WORKDIR)           \
			  -v $(PACKAGES):$(WORKDIR)/packages \
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
ARCH  	= $(shell gcc -dumpmachine)
WORKDIR = $(shell pwd)

##############################################################################
# Build Binaries & Libraries

vpath %.u libs

# Example:
#  	#1. REMOTE_HOST=10.10.10.234 make zlib
# 	#2. DOCKER_IMAGE=unistatic make zlib
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

prepare-docker-image:
	docker build                                  \
		-t $(DOCKER_IMAGE)                        \
		--build-arg LANG=${LANG}                  \
		--build-arg TZ=$(TIMEZONE)                \
		--build-arg MIRROR=http://cache.mtdcy.top \
		.

# Please install 'Command Line Tools' first
prepare-remote-homebrew:
	$(REMOTE_EXEC) '$$SHELL -li -c "brew install    \
			wget curl git                           \
			gnu-tar xz lzip unzip                   \
			autoconf libtool pkg-config cmake meson \
			nasm yasm bison flex                    \
			luajit perl                             \
			"'

prepare-remote-debian:
	$(REMOTE_EXEC) 'sudo apt install -y             \
			wget curl git                           \
			xz-utils lzip unzip                     \
			build-essential                         \
			autoconf libtool pkg-config cmake meson \
			nasm yasm bison flex                    \
			luajit perl libhttp-daemon-perl         \
			'

# TODO
prepare-remote-msys2:
	$(REMOTE_EXEC)

##############################################################################
# remote:
# 	#1. rsync with ssh is the best way, no extra utils or services is needed.
# 	#2. using default $SHELL instead of bash, as remote may set PATH for default login shell only.
# 	#3. always request a TTY => https://community.hpe.com/t5/operating-system-linux/sshmake-session-quot-tput-no-value-for-term-and-no-t-specified/td-p/5255040
push-remote:
	@./ulog.sh info "@Push" "$(WORKDIR) => $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	@$(REMOTE_SYNC) --exclude='packages' --exclude='prebuilts' --exclude='out' $(WORKDIR)/ $(REMOTE_HOST):$(REMOTE_WORKDIR)/

pull-remote:
	@./ulog.sh info "@Pull" "$(REMOTE_HOST):$(REMOTE_WORKDIR) => $(WORKDIR)"
	@$(REMOTE_SYNC) --exclude='$(ARCH)' $(REMOTE_HOST):$(REMOTE_WORKDIR)/prebuilts/ $(WORKDIR)/prebuilts/

exec-remote: push-remote
	@./ulog.sh info "SHELL" "$(CMD) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_EXEC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && $(ENVs) $(CMD)"'
	@make pull-remote
	@./ulog.sh info "@END@" "Leaving $(REMOTE_HOST):$(REMOTE_WORKDIR)"

##############################################################################
# docker
exec-docker:
	@./ulog.sh info "SHELL" "$(CMD) @ docker ($(DOCKER_IMAGE))"
	$(DOCKER_EXEC) 'cd $(WORKDIR) && $(ENVs) $(CMD)'
	@./ulog.sh info "@END@" "Leaving $(DOCKER_IMAGE)"

##############################################################################
# Install prebuilts @ Host
PREBUILTS = $(wildcard prebuilts/*)

# always update by checksum
update: $(PREBUILTS)
ifeq ($(HOST),)
	@for arch in $(PREBUILTS); do                                      \
		./ulog.sh info "Update" "$$arch/ ==> $(DEST)/$$arch/";         \
		mkdir -p $(DEST)/$$arch/;                                      \
		rsync -avc $$arch/ $(DEST)/$$arch/;                            \
	done
else
	@for arch in $(PREBUILTS); do                                      \
		./ulog.sh info "Update" "$$arch/ ==> $(HOST):$(DEST)/$$arch/"; \
		ssh $(HOST) mkdir -p $(DEST)/$$arch/;                          \
		rsync -avcz -e ssh $$arch/ $(HOST):$(DEST)/$$arch/;            \
	done
endif

ARCHIVE_DEST = $(shell dirname $(DEST))/$(shell date +%Y.%m.%d)

archive:
ifeq ($(HOST),)
		@./ulog.sh info "Archive" "$(DEST) => $(ARCHIVE_DEST)"
		@mv -T $(DEST) $(ARCHIVE_DEST)
else
		@./ulog.sh info "Archive" "$(DEST) => $(HOST):$(ARCHIVE_DEST)"
		@ssh $(HOST) 'mv -T $(DEST) $(ARCHIVE_DEST)'
endif

install: archive update

.PHONY: install update archive
.NOTPARALLEL: all

zip:
	tar -Jcvf $(shell date +%Y.%m.%d).tar.xz prebuilts

# vim:ft=make:ff=unix:fenc=utf-8:noet:sw=4:sts=0
