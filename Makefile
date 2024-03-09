all: build

LIB ?=
NJOBS ?= 

# package cache dir for docker volume mount
PACKAGES ?= /mnt/Service/Caches/packages
DOCKER_IMAGE ?= mtdcy/unistatic

REMOTE ?= 10.10.10.234
REMOTE_WORKDIR ?= ~/UniStatic

DEST ?= /mnt/Service/Downloads/public/UniStatic

# internal variables
USER := $(shell id -u)
GROUP := $(shell id -g)
WORKDIR := $(shell pwd)

ARGS := 

build-image:
	docker build -t $(DOCKER_IMAGE) --build-arg MIRROR=http://cache.mtdcy.top .

build-ffmpeg:
	docker run --rm -it                    \
		-u $(USER):$(GROUP)                \
		-v $(WORKDIR):$(WORKDIR)           \
		-v $(PACKAGES):$(WORKDIR)/packages \
		$(DOCKER_IMAGE)                    \
		bash -c 'cd $(WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.ffmpeg.sh; exit'

build-lib: $(LIB)
	docker run --rm -it                    \
		-u $(USER):$(GROUP)                \
		-v $(WORKDIR):$(WORKDIR)           \
		-v $(PACKAGES):$(WORKDIR)/packages \
		$(DOCKER_IMAGE)                    \
		bash -c 'cd $(WORKDIR) && . ulib.sh && UPKG_NJOBS=$(NJOBS) upkg_build $(LIB); exit'

sync-remote:
	rsync -av -e 'ssh' *.sh $(REMOTE):$(REMOTE_WORKDIR)/


build-ffmpeg-remote: sync-remote
	ssh $(REMOTE) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.ffmpeg.sh"'

build-lib-remote: sync-remote
	ssh $(REMOTE) '$$SHELL -l -c "cd $(REMOTE_WORKDIR) && . ./ulib.sh && UPKG_NJOBS=$(NJOBS) upkg_build $(LIB)"'

dev:
	docker run --rm -it                    \
		-u $(USER):$(GROUP)                \
		-v $(WORKDIR):$(WORKDIR)           \
		-v $(PACKAGES):$(WORKDIR)/packages \
		$(DOCKER_IMAGE)                    \
		bash -c 'cd $(WORKDIR) && bash'

public:
	mkdir -pv $(DEST)
	rsync -avc prebuilts $(DEST)/current/

# make sure dest exists
public-remote:
	rsync -av -e 'ssh' prebuilts 10.10.10.254:$(DEST)/current/

zip: 
	tar -Jcvf $(shell date +%Y.%m.%d).tar.xz prebuilts
