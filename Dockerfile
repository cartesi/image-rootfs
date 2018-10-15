FROM cartesi/image-toolchain:latest

MAINTAINER Diego Nehab <diego.nehab@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

ENV OLDPATH=$PATH

# Build rootfs with ABI lp64 and ISA rv64ima
# ----------------------------------------------------
ENV ARCH "rv64ima"
ENV ABI "lp64"
ENV RISCV "$BASE/toolchain/linux/$ARCH-$ABI"
ENV PATH "$RISCV/bin:${OLDPATH}"

RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        rsync cpio && \
    rm -rf /var/lib/apt/lists/*

RUN \
    git clone --branch cartesi --depth 1 \
        https://github.com/cartesi/buildroot.git

COPY skel $BASE/buildroot/skel
COPY cartesi-config $BASE/buildroot

# Never use -jN with buildroot
RUN \
    mkdir -p $BASE/buildroot/work && \
    cd $BASE/buildroot && \
    git pull && \
    cp cartesi-config work/.config && \
    make O=work olddefconfig && \
    make -C work && \
    cp work/images/rootfs.ext2 $BASE

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]
