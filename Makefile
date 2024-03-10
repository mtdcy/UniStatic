all:

LIBS ?=
NJOBS ?= 

# publish prebuilts to HOST:DEST
HOST ?= 
DEST ?= /mnt/Service/Downloads/public/UniStatic

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
DOCKER_EXEC  := docker run --rm -it               \
			   -u $(USER):$(GROUP)                \
			   -v $(WORKDIR):$(WORKDIR)           \
			   -v $(PACKAGES):$(WORKDIR)/packages \
			   $(DOCKER_IMAGE) bash -li -c

REMOTE_SYNC := rsync -e 'ssh' -avcz --delete-after --exclude='.*'
REMOTE_EXEC := ssh $(REMOTE_HOST) -t 

preapre-docker-image:
	docker build -t $(DOCKER_IMAGE) --build-arg MIRROR=http://cache.mtdcy.top .

# Please install 'Command Line Tools' first
prepare-remote-homebrew:
	$(REMOTE_EXEC) '$$SHELL -li -c "brew install wget git autoconf libtool pkg-config cmake meson nasm yasm"'

# TODO
prepare-remote-msys2:
	$(REMOTE_EXEC) 

push-remote:
	$(REMOTE_SYNC) --exclude='packages' --exclude='prebuilts' --exclude='out' $(WORKDIR)/ $(REMOTE_HOST):$(REMOTE_WORKDIR)/

pull-remote:
	$(REMOTE_SYNC) --exclude='$(ARCH)' $(REMOTE_HOST):$(REMOTE_WORKDIR)/prebuilts/ $(WORKDIR)/prebuilts/

exec:
	$(DOCKER_EXEC) 'cd $(WORKDIR) && bash'

libs-docker:
	$(DOCKER_EXEC) 'cd $(WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.sh $(LIBS)'

# using default $SHELL instead of bash, as remote may set PATH for login shell only.
libs-remote: push-remote
	$(REMOTE_EXEC) 'cd $(REMOTE_WORKDIR) && $$SHELL -li -c "UPKG_NJOBS=$(NJOBS) ./build.sh $(LIBS)"'

ffmpeg-docker:
	$(DOCKER_EXEC) 'cd $(WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.ffmpeg.sh'

ffmpeg-remote: push-remote
	$(REMOTE_EXEC) 'cd $(REMOTE_WORKDIR) && $$SHELL -li -c "UPKG_NJOBS=$(NJOBS) ./build.ffmpeg.sh"'

##############################################################################
# Install prebuilts
PREBUILTS := $(wildcard prebuilts/*)

# No '--delete' when publish
publish: $(PREBUILTS)
ifeq ($(HOST),)
	@for arch in $(PREBUILTS); do                                   \
		echo "$$arch/ ==> $(DEST)/current/$$arch/";                 \
		mkdir -pv $(DEST)/current/$$arch/;                          \
		rsync -av $$arch/ $(DEST)/current/$$arch/;                  \
	done
else
	@for arch in $(PREBUILTS); do                                   \
		echo "$$arch/ ==> $(HOST):$(DEST)/current/$$arch/";         \
		ssh $(HOST) -t mkdir -pv $(DEST)/current/$$arch/;           \
		rsync -avcz -e ssh $$arch/ $(HOST):$(DEST)/current/$$arch/; \
	done
endif

install: publish

.PHONY: install

zip:
	tar -Jcvf $(shell date +%Y.%m.%d).tar.xz prebuilts
