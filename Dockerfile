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

ARG TOOLCHAIN_REPOSITORY=cartesi/toolchain
ARG TOOLCHAIN_VERSION=latest
FROM ${TOOLCHAIN_REPOSITORY}:${TOOLCHAIN_VERSION}

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

ENV BUILD_BASE=$BASE/rootfs

ARG RISCV_ARCH=rv64ima
ARG RISCV_ABI=lp64
ENV ARCH $RISCV_ARCH
ENV ABI $RISCV_ABI

ENV RISCV "$BASE/riscv64-cartesi-linux-gnu"
ENV PATH "$RISCV/bin:${OLDPATH}"

RUN \
    mkdir -p $BUILD_BASE/artifacts

RUN \
    chown -R developer:developer $BUILD_BASE && \
    chmod o+w $BUILD_BASE

USER developer

RUN \
    cd $BUILD_BASE && \
    git clone --branch 2022.02.3 --depth 1 \
        https://github.com/buildroot/buildroot.git

COPY --chown=developer:developer skel $BUILD_BASE/buildroot/skel
COPY --chown=developer:developer cartesi-buildroot-config $BUILD_BASE/buildroot
COPY --chown=developer:developer cartesi-busybox-fragment $BUILD_BASE/buildroot
COPY --chown=developer:developer patches $BUILD_BASE/buildroot/patches
COPY --chown=developer:developer external $BUILD_BASE/buildroot/external
COPY --chown=developer:developer local.mk $BUILD_BASE/buildroot/local.mk

# Never use -jN with buildroot
RUN \
    mkdir -p $BUILD_BASE/buildroot/work && \
    cd $BUILD_BASE/buildroot && \
    git pull && \
    git apply patches/* && \
    cp cartesi-buildroot-config work/.config && \
    cp local.mk work/local.mk && \
    make BR2_EXTERNAL=$BUILD_BASE/buildroot/external O=work olddefconfig && \
    make -C work && \
    cp work/images/rootfs.ext2 $BUILD_BASE/artifacts && \
    truncate -s %4096 $BUILD_BASE/artifacts/rootfs.ext2

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]
