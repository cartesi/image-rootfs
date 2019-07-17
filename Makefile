.PHONY: build push run share

TAG ?= latest
TOOLCHAIN_TAG ?=

CONTAINER_BASE := /opt/cartesi/image-rootfs

IMG:=cartesi/image-rootfs:$(TAG)
BASE:=/opt/riscv
ART:=$(BASE)/rootfs.ext2

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS := --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

all: copy

build:
	docker build -t $(IMG) $(BUILD_ARGS) .

push:
	docker push $(IMG)

run:
	docker run --hostname toolchain-env -it --rm \
		-e USER=$$(id -u -n) \
		-e GROUP=$$(id -g -n) \
		-e UID=$$(id -u) \
		-e GID=$$(id -g) \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

run-as-root:
	docker run --hostname toolchain-env -it --rm \
		$(IMG) $(CONTAINER_COMMAND)

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID
