all: build

LIB ?=
NJOBS ?= $(shell nproc)
PACKAGES ?= /mnt/Service/Caches/packages
DOCKER_IMAGE ?= mtdcy/unistatic

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

build:
	docker run --rm -it                    \
		-u $(USER):$(GROUP)                \
		-v $(WORKDIR):$(WORKDIR)           \
		-v $(PACKAGES):$(WORKDIR)/packages \
		$(DOCKER_IMAGE)                    \
		bash -c 'cd $(WORKDIR) && bash'

build-lib:
	docker run --rm -it                    \
		-u $(USER):$(GROUP)                \
		-v $(WORKDIR):$(WORKDIR)           \
		-v $(PACKAGES):$(WORKDIR)/packages \
		$(DOCKER_IMAGE)                    \
		bash -c 'cd $(WORKDIR) && export UPKG_NJOBS=$(NJOBS); . ulib.sh; upkg_build $(LIB); exit'

