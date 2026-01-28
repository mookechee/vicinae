# DEB Builder Docker Image

This directory contains the Dockerfile for building Vicinae DEB packages.

## Overview

The Docker image is based on **Ubuntu 22.04** to ensure forward compatibility with:
- Debian 12 (Bookworm)
- Ubuntu 22.04 (Jammy)
- Ubuntu 24.04 (Noble)

## How It Works

### Automatic Image Management

The CI workflow automatically:
1. Calculates a hash of the Dockerfile
2. Checks if an image with that hash exists in ghcr.io
3. Builds and pushes a new image only if the Dockerfile changed
4. Uses the cached image for subsequent builds

### Image Tags

- `ghcr.io/<owner>/<repo>/deb-builder:<dockerfile-hash>` - Content-addressed tag
- `ghcr.io/<owner>/<repo>/deb-builder:latest` - Always points to the most recent image

## Local Development

### Build the image locally

```bash
docker build -t vicinae-deb-builder -f scripts/runners/deb/Dockerfile .
```

### Build a DEB package locally

```bash
docker run --rm -v $(pwd):/work vicinae-deb-builder -c "./scripts/mkdeb.sh"
```

### Interactive shell

```bash
docker run --rm -it -v $(pwd):/work vicinae-deb-builder
```

## Compatibility Notes

### Why Ubuntu 22.04?

- **glibc 2.35**: The oldest glibc version among target distributions
- **Qt 6.2.4**: Compatible with all target distributions (they have Qt 6.2+)
- **No layer-shell-qt**: Built from source via CMake (`USE_SYSTEM_LAYER_SHELL=OFF`)

### Dependency Resolution

The `debian/control` file uses the `|` (OR) syntax for package alternatives:
```
libqt6core6 | libqt6core6t64
```

This ensures compatibility with:
- Ubuntu 22.04/Debian 12: Uses `libqt6core6`
- Ubuntu 24.04: Uses `libqt6core6t64` (64-bit time_t transition)

## Installed Packages

The image includes all packages from `debian/control` Build-Depends plus:
- `devscripts`, `debhelper`, `lintian` - Debian packaging tools
- `ccache` - Build cache for faster incremental builds
- `git` - Required for version detection
