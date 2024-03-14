all:

LIBS ?=
NJOBS ?=
COMMAND ?=

# publish prebuilts to HOST:DEST
HOST ?= 
DEST ?= /mnt/Service/Downloads/public/UniStatic/current

# package cache dir for docker volume mount
PACKAGES ?= /mnt/Service/Caches/packages

REMOTE_HOST ?= 10.10.10.234
REMOTE_WORKDIR ?= ~/UniStatic

# internal variables
USER  = $(shell id -u)
GROUP = $(shell id -g)
ARCH  = $(shell gcc -dumpmachine)

WORKDIR = $(shell pwd)

DOCKER_IMAGE := mtdcy/unistatic
DOCKER_EXEC  := docker run --rm -it					\
				-u $(USER):$(GROUP)					\
				-v $(WORKDIR):$(WORKDIR)			\
				-v $(PACKAGES):$(WORKDIR)/packages	\
				$(DOCKER_IMAGE) bash -li -c

REMOTE_SYNC := rsync -e 'ssh' -acz --exclude='.*'
REMOTE_EXEC := ssh $(REMOTE_HOST) -tq -o "BatchMode yes"

##############################################################################
# prepare
#########
prepare-docker-image:
	docker build -t $(DOCKER_IMAGE) --build-arg MIRROR=http://cache.mtdcy.top .

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

clean:
	@./ulog.sh info Clean out
	rm -rf out

distclean: clean
	@./ulog.sh info Clean prebuilts
	rm -rf prebuilts

.PHONY: clean distclean

##############################################################################
# remote
#########
push-remote:
	@./ulog.sh info ".Push" "$(WORKDIR) => $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	@$(REMOTE_SYNC) --exclude='packages' --exclude='prebuilts' --exclude='out' $(WORKDIR)/ $(REMOTE_HOST):$(REMOTE_WORKDIR)/

pull-remote:
	@./ulog.sh info ".Pull" "$(REMOTE_HOST):$(REMOTE_WORKDIR) => $(WORKDIR)"
	@$(REMOTE_SYNC) --exclude='$(ARCH)' $(REMOTE_HOST):$(REMOTE_WORKDIR)/prebuilts/ $(WORKDIR)/prebuilts/

#1. using default $SHELL instead of bash, as remote may set PATH for login shell only.
#2. always request a TTY => https://community.hpe.com/t5/operating-system-linux/ssh-session-quot-tput-no-value-for-term-and-no-t-specified/td-p/5255040
remote-build: push-remote
	@./ulog.sh info "Build" "$(LIBS) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_EXEC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.sh $(LIBS)"'

remote-exec: push-remote
	@./ulog.sh info "..Run" "$(COMMAND) @ $(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_EXEC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && $(COMMAND)"'

remote-clean: push-remote
	@./ulog.sh info "Clean" "$(REMOTE_HOST):$(REMOTE_WORKDIR)"
	$(REMOTE_EXEC) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && make clean"'

##############################################################################
# docker
########
docker-build:
	@./ulog.sh info "Build" "$(LIBS) @ docker"
	@$(DOCKER_EXEC) 'cd $(WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.sh $(LIBS)'

docker-exec:
	@./ulog.sh info "..Run" "$(COMMAND) @ docker"
	@$(DOCKER_EXEC) 'cd $(WORKDIR) && bash $(COMMAND)'

docker-clean: clean
	@./ulog.sh info "Clean" "docker"

.PHONY: docker-clean

##############################################################################
# Install prebuilts
PREBUILTS := $(wildcard prebuilts/*)

update: $(PREBUILTS)
ifeq ($(HOST),)
	@for arch in $(PREBUILTS); do                                      \
		./ulog.sh info "Update" "$$arch/ ==> $(DEST)/$$arch/";         \
		mkdir -p $(DEST)/$$arch/;                                      \
		rsync -av $$arch/ $(DEST)/$$arch/;                             \
	done
else
	@for arch in $(PREBUILTS); do                                      \
		./ulog.sh info "Update" "$$arch/ ==> $(HOST):$(DEST)/$$arch/"; \
		ssh $(HOST) mkdir -p $(DEST)/$$arch/;                          \
		rsync -avcz -e ssh $$arch/ $(HOST):$(DEST)/$$arch/;            \
	done
endif

ARCHIVE_DEST := $(shell dirname $(DEST))/$(shell date +%Y.%m.%d)

archive:
ifeq ($(HOST),)
		@./ulog.sh info "Archive" "$(DEST) => $(ARCHIVE_DEST)"
		@mv -T $(DEST) $(ARCHIVE_DEST)
else
		@./ulog.sh info "Archive" "$(DEST) => $(HOST):$(ARCHIVE_DEST)"
		@ssh $(HOST) 'mv -T $(DEST) $(ARCHIVE_DEST)'
endif

install: archive update 

.PHONY: install
.NOTPARALLEL: all

zip:
	tar -Jcvf $(shell date +%Y.%m.%d).tar.xz prebuilts

# vim:ft=make:ff=unix:fenc=utf-8:noet:sw=8:sts=0
