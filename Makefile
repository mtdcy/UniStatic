all: build-ffmpeg 

USER := $(shell id -u)
GROUP := $(shell id -g)
WORKDIR := $(shell pwd)
IMAGE := mtdcy/ubuntu:22.04-dev
PACKAGES := /mnt/Service/Caches/packages

build-ffmpeg:
	docker run --rm                                               \
		-u $(USER):$(GROUP)                                       \
		-v $(WORKDIR):$(WORKDIR)                                  \
		-v $(PACKAGES):$(WORKDIR)/packages                        \
		$(IMAGE)                                                  \
		bash -c "cd $(WORKDIR) && UPKG_NJOBS=8 ./build.ffmpeg.sh"

build-ffmpeg-release:
	docker run --rm                                               \
		-u $(USER):$(GROUP)                                       \
		-v $(WORKDIR):$(WORKDIR)                                  \
		-v $(PACKAGES):$(WORKDIR)/packages                        \
		$(IMAGE)                                                  \
		bash -c "cd $(WORKDIR) && ./build.ffmpeg.sh"

build:
	docker run --rm -it                                           \
		-u $(USER):$(GROUP)                                       \
		-v $(WORKDIR):$(WORKDIR)                                  \
		-v $(PACKAGES):$(WORKDIR)/packages                        \
		$(IMAGE)                                                  \
		bash -c 'cd $(WORKDIR) && bash'

