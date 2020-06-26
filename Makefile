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

.PHONY: build push run share

TAG ?= devel
TOOLCHAIN_TAG ?= 0.3.0
NEW_TAG ?= latest
BUILDROOT_CONFIG ?= configs/default-buildroot-config
BUSYBOX_CONFIG ?= configs/default-busybox-fragment

CONTAINER_BASE := /opt/cartesi/rootfs

IMG_REPO:=cartesi/rootfs
IMG:=$(IMG_REPO):$(TAG)
BASE:=/opt/riscv
ART:=$(BASE)/rootfs/artifacts/rootfs.ext2
YIELD_BIN:=tools/linux/htif/yield

ifneq ($(TOOLCHAIN_TAG),)
BUILD_ARGS := --build-arg TOOLCHAIN_VERSION=$(TOOLCHAIN_TAG)
endif

all: copy

submodules:
	git submodule update --init --recursive

$(YIELD_BIN):
	$(MAKE) -C tools/linux/htif TOOLCHAIN_TAG=$(TOOLCHAIN_TAG)

yield: $(YIELD_BIN)

build: $(YIELD_BIN) cartesi-buildroot-config cartesi-busybox-fragment
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

clean-config:
	rm -f ./cartesi-buildroot-config ./cartesi-busybox-fragment

clean: clean-config
	$(MAKE) -C tools/linux/htif TOOLCHAIN_TAG=$(TOOLCHAIN_TAG) clean
	rm -f rootfs.ext2

copy: build
	ID=`docker create $(IMG)` && docker cp $$ID:$(ART) . && docker rm -v $$ID
