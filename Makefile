all: build-ffmpeg 

NJOBS ?= 8
IMAGE ?= mtdcy/ubuntu:22.04-dev
PACKAGES ?= /mnt/Service/Caches/packages

USER := $(shell id -u)
GROUP := $(shell id -g)
WORKDIR := $(shell pwd)

build-ffmpeg:
	docker run --rm                                                      	\
		-u $(USER):$(GROUP)                                              	\
		-v $(WORKDIR):$(WORKDIR)                                         	\
		-v $(PACKAGES):$(WORKDIR)/packages                               	\
		$(IMAGE)                                                         	\
		bash -c "cd $(WORKDIR) && UPKG_NJOBS=$(NJOBS) ./build.ffmpeg.sh"

build-ffmpeg-release:
	docker run --rm                                                      	\
		-u $(USER):$(GROUP)                                              	\
		-v $(WORKDIR):$(WORKDIR)                                         	\
		-v $(PACKAGES):$(WORKDIR)/packages                               	\
		$(IMAGE)                                                         	\
		bash -c "cd $(WORKDIR) && ./build.ffmpeg.sh"

build:
	docker run --rm -it                                                  	\
		-u $(USER):$(GROUP)                                              	\
		-v $(WORKDIR):$(WORKDIR)                                         	\
		-v $(PACKAGES):$(WORKDIR)/packages                               	\
		$(IMAGE)                                                         	\
		bash -c 'cd $(WORKDIR) && bash'

