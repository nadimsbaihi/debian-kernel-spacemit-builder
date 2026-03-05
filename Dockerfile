FROM debian:bookworm AS builder

ARG KERNEL_BRANCH=linux-6.18.y
ARG KERNEL_REPO=https://github.com/jmontleon/linux-spacemit.git
ARG LOCALVERSION=-spacemit
ARG KDEB_PKGVERSION=6.18.13-1
ARG JOBS=0

ENV DEBIAN_FRONTEND=noninteractive

# -- 1. Build dependencies ----------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-riscv64-linux-gnu \
    g++-riscv64-linux-gnu \
    binutils-riscv64-linux-gnu \
    libssl-dev \
    libelf-dev \
    libdw-dev \
    bc \
    kmod \
    cpio \
    flex \
    bison \
    dwarves \
    rsync \
    wget \
    curl \
    rpm2cpio \
    git \
    ca-certificates \
    python3 \
    xz-utils \
    zstd \
    lz4 \
    debhelper \
    && rm -rf /var/lib/apt/lists/*

# Fix Debian multiarch: opensslconf.h lives in the arch-specific include dir
RUN ln -sf /usr/include/x86_64-linux-gnu/openssl/opensslconf.h /usr/include/openssl/ && \
    ln -sf /usr/include/x86_64-linux-gnu/openssl/configuration.h /usr/include/openssl/

# -- 2. Clone the patched kernel tree -----------------------------------------
WORKDIR /build
RUN git clone --depth 1 -b ${KERNEL_BRANCH} ${KERNEL_REPO} linux

# -- 3. Configure using the Fedora SpacemiT config ----------------------------
WORKDIR /build/linux
RUN make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- CUSTOM_defconfig

# -- 4. Build Debian packages -------------------------------------------------
#    DPKG_FLAGS="-d" skips dpkg-checkbuilddeps (avoids :native suffix issues)
RUN PARALLEL="${JOBS}"; \
    if [ "${PARALLEL}" = "0" ] || [ -z "${PARALLEL}" ]; then PARALLEL="$(nproc)"; fi && \
    make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- \
    LOCALVERSION=${LOCALVERSION} \
    KDEB_PKGVERSION=${KDEB_PKGVERSION} \
    DPKG_FLAGS="-d" \
    bindeb-pkg \
    -j"${PARALLEL}"

# -- 5. Collect the .deb output ------------------------------------------------
RUN mkdir -p /out && cp /build/*.deb /out/

# -- Final stage: slim image with just the debs --------------------------------
FROM scratch AS export
COPY --from=builder /out/ /
