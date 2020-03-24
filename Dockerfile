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

ARG TOOLCHAIN_VERSION=latest
FROM cartesi/toolchain:${TOOLCHAIN_VERSION}

LABEL maintainer="Diego Nehab <diego@cartesi.io>"

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

# Build rootfs with ABI lp64 and ISA rv64ima
# ----------------------------------------------------
ENV ARCH "rv64ima"
ENV ABI "lp64"
ENV RISCV "$BASE/riscv64-unknown-linux-gnu"
ENV PATH "$RISCV/bin:${OLDPATH}"

RUN \
    git clone --branch 2020.02 --depth 1 \
        https://github.com/buildroot/buildroot.git

COPY skel $BASE/buildroot/skel
COPY cartesi-config $BASE/buildroot
COPY patches $BASE/buildroot/patches
COPY tools/linux/htif/extra $BASE/buildroot/skel/opt/cartesi/bin

# Never use -jN with buildroot
RUN \
    chmod +x $BASE/buildroot/skel/opt/cartesi/bin/* && \
    mkdir -p $BASE/buildroot/work && \
    cd $BASE/buildroot && \
    git pull && \
    git apply patches/* && \
    cp cartesi-config work/.config && \
    make O=work olddefconfig && \
    make -C work && \
    cp work/images/rootfs.ext2 $BASE && \
    truncate -s %4096 $BASE/rootfs.ext2

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]
