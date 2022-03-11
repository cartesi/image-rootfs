# Copyright 2019 Cartesi Pte. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.
#

.PHONY: build push run share init-config copy

TAG ?= devel
TOOLCHAIN_DOCKER_REPOSITORY ?= cartesi/toolchain
TOOLCHAIN_TAG ?= 0.9.0
NEW_TAG ?= latest
BUILDROOT_CONFIG ?= configs/default-buildroot-config
BUSYBOX_CONFIG ?= configs/default-busybox-fragment
RISCV_ARCH ?= rv64ima
RISCV_ABI ?= lp64

ifeq ($(fd_emulation),yes)
BUILDROOT_CONFIG = configs/lp64d-buildroot-config
RISCV_ARCH = rv64imafd
RISCV_ABI = lp64d
endif

CONTAINER_BASE := /opt/cartesi/rootfs

IMG_REPO ?= cartesi/rootfs
IMG ?= $(IMG_REPO):$(TAG)
BASE:=/opt/riscv
ART:=$(BASE)/rootfs/artifacts/rootfs.ext2

ifneq ($(TOOLCHAIN_DOCKER_REPOSITORY),)
BUILD_ARGS := --build-arg TOOLCHAIN_REPOSITORY=$(TOOLCHAIN_DOCKER_REPOSITORY)
endif

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS += --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

BUILD_ARGS += --build-arg RISCV_ARCH=$(RISCV_ARCH)
BUILD_ARGS += --build-arg RISCV_ABI=$(RISCV_ABI)

.NOTPARALLEL: all
all: build copy

build: init-config
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

tag:
	docker tag $(IMG) $(IMG_REPO):$(NEW_TAG)

run-as-root:
	docker run --hostname toolchain-env -it --rm \
		-v `pwd`:$(CONTAINER_BASE) \
		-w $(CONTAINER_BASE) \
		$(IMG) $(CONTAINER_COMMAND)

config: CONTAINER_COMMAND := $(CONTAINER_BASE)/scripts/update-buildroot-config
config: cartesi-buildroot-config cartesi-busybox-fragment run-as-root

cartesi-buildroot-config:
	cp $(BUILDROOT_CONFIG) ./cartesi-buildroot-config

cartesi-busybox-fragment:
	cp $(BUSYBOX_CONFIG) ./cartesi-busybox-fragment

init-config: cartesi-buildroot-config cartesi-busybox-fragment

clean-config:
	rm -f ./cartesi-buildroot-config ./cartesi-busybox-fragment

clean: clean-config
	rm -f rootfs.ext2

copy:
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID
