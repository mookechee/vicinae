# DEB package build environment for Vicinae.
# Based on the same Ubuntu 22.04 + custom GCC/Qt stack as the AppImage builder,
# but with additional Debian packaging tools.

FROM ghcr.io/mookechee/vicinae-build-env:latest AS base

# Install Debian packaging tools
RUN apt-get update && apt-get install -y \
    dpkg-dev \
    debhelper \
    devscripts \
    lintian \
    fakeroot \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

ENTRYPOINT ["/bin/bash"]
