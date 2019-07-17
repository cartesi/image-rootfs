ARG TOOLCHAIN_VERSION=latest
FROM cartesi/image-toolchain:${TOOLCHAIN_VERSION}

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
    git clone --branch 2019.05.1 --depth 1 \
        https://github.com/buildroot/buildroot.git

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
    cp work/images/rootfs.ext2 $BASE && \
    truncate -s %4096 $BASE/rootfs.ext2

USER root

WORKDIR $BASE

CMD ["/bin/bash", "-l"]
