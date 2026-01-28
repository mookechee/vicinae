# Build environment for Vicinae DEB packages
# Based on Ubuntu 22.04 for forward compatibility with Debian 12 and Ubuntu 24.04
FROM ubuntu:22.04

LABEL maintainer="Vicinae Developers <dev@vicinae.org>"
LABEL description="Build environment for Vicinae DEB packages"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install all build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # ===== Basic build tools =====
    build-essential \
    devscripts \
    debhelper \
    lintian \
    fakeroot \
    git \
    ca-certificates \
    # ===== CMake and build system =====
    cmake \
    ninja-build \
    pkg-config \
    # ===== Qt6 development libraries =====
    qt6-base-dev \
    qt6-wayland-dev \
    libqt6svg6-dev \
    libqt6sql6-sqlite \
    # ===== OpenGL (required by Qt6Gui) =====
    libgl-dev \
    libegl-dev \
    # ===== Secret storage (for Qt Keychain) =====
    libsecret-1-dev \
    # ===== Wayland =====
    libwayland-dev \
    wayland-protocols \
    # ===== X11/XCB =====
    libx11-dev \
    libxcb1-dev \
    libxkbcommon-dev \
    # ===== Other libraries =====
    libqalculate-dev \
    libssl-dev \
    libxml2-dev \
    libminizip-dev \
    libicu-dev \
    # ===== Node.js =====
    nodejs \
    npm \
    # ===== Build acceleration =====
    ccache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure ccache
ENV PATH="/usr/lib/ccache:${PATH}"
ENV CCACHE_DIR="/ccache"
ENV CCACHE_MAXSIZE="2G"

WORKDIR /work

ENTRYPOINT ["/bin/bash"]
