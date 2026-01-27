#!/bin/bash
#
# Build a DEB package for Vicinae.
# This script is meant to be run inside the DEB build Docker container.
#
# Usage: mkdeb.sh [--skip-build]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
STAGING_DIR="${PROJECT_ROOT}/debian/vicinae"
OUTPUT_DIR="${PROJECT_ROOT}"

# Parse arguments
SKIP_BUILD=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cd "${PROJECT_ROOT}"

echo "==> Starting DEB package build"
echo "    Project root: ${PROJECT_ROOT}"
echo "    Build dir: ${BUILD_DIR}"
echo "    Staging dir: ${STAGING_DIR}"

# Get version from manifest.yaml or git
get_version() {
    if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
        git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"
    elif [ -f "${PROJECT_ROOT}/manifest.yaml" ]; then
        grep 'tag:' "${PROJECT_ROOT}/manifest.yaml" | head -1 | sed 's/.*tag: *"v\([^"]*\)".*/\1/'
    else
        echo "0.0.0"
    fi
}

VERSION=$(get_version)
echo "    Version: ${VERSION}"

# Update debian/changelog with current version
update_changelog() {
    local version="$1"
    local changelog="${PROJECT_ROOT}/debian/changelog"

    # Read current changelog to preserve format
    if grep -q "^vicinae (${version}-" "${changelog}" 2>/dev/null; then
        echo "    Changelog already at version ${version}"
        return
    fi

    # Create new changelog entry
    local date_str
    date_str=$(date -R)

    cat > "${changelog}" <<EOF
vicinae (${version}-1) unstable; urgency=medium

  * Release ${version}

 -- Vicinae Team <contact@vicinae.com>  ${date_str}
EOF
}

update_changelog "${VERSION}"

# Step 1: Configure and build
if [ "${SKIP_BUILD}" = false ]; then
    echo "==> Configuring CMake"
    cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DVICINAE_PROVENANCE=deb \
        -DLTO=ON \
        -DUSE_SYSTEM_PROTOBUF=OFF \
        -DUSE_SYSTEM_ABSEIL=OFF \
        -DUSE_SYSTEM_CMARK_GFM=OFF \
        -B "${BUILD_DIR}"

    echo "==> Building"
    cmake --build "${BUILD_DIR}" --parallel "$(nproc)"
fi

# Step 2: Install to staging directory
echo "==> Installing to staging directory"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

DESTDIR="${STAGING_DIR}" cmake --install "${BUILD_DIR}"

# Step 3: Bundle Node.js
echo "==> Bundling Node.js"
NODE_BIN=$(which node 2>/dev/null || echo "/opt/node/bin/node")
if [ -f "${NODE_BIN}" ]; then
    mkdir -p "${STAGING_DIR}/usr/bin"
    cp "${NODE_BIN}" "${STAGING_DIR}/usr/bin/node"
    chmod +x "${STAGING_DIR}/usr/bin/node"
    echo "    Bundled node from ${NODE_BIN}"
else
    echo "    [WARN] Node.js binary not found, extension manager may not work"
fi

# Step 4: Bundle Qt libraries
echo "==> Bundling Qt libraries"
"${SCRIPT_DIR}/bundle-qt-libs.sh" "${STAGING_DIR}"

# Step 5: Strip binaries
echo "==> Stripping binaries"
if [ -f "${STAGING_DIR}/usr/bin/vicinae" ]; then
    strip --strip-unneeded "${STAGING_DIR}/usr/bin/vicinae" 2>/dev/null || true
fi
find "${STAGING_DIR}/usr/lib" -name "*.so*" -type f -exec strip --strip-unneeded {} \; 2>/dev/null || true

# Step 6: Set correct permissions
echo "==> Setting permissions"
find "${STAGING_DIR}" -type d -exec chmod 755 {} \;
find "${STAGING_DIR}" -type f -exec chmod 644 {} \;
chmod 755 "${STAGING_DIR}/usr/bin/vicinae"
chmod 755 "${STAGING_DIR}/usr/bin/node"
find "${STAGING_DIR}/usr/lib" -name "*.so*" -type f -exec chmod 755 {} \;

# Step 7: Build the DEB package
echo "==> Building DEB package"
cd "${PROJECT_ROOT}"

# Use dpkg-buildpackage
dpkg-buildpackage -us -uc -b --no-check-builddeps

# Move the generated .deb to output directory
DEB_FILE=$(ls -1 "${PROJECT_ROOT}/../vicinae_${VERSION}"*.deb 2>/dev/null | head -1)
if [ -n "${DEB_FILE}" ] && [ -f "${DEB_FILE}" ]; then
    mv "${DEB_FILE}" "${OUTPUT_DIR}/"
    DEB_FILE="${OUTPUT_DIR}/$(basename "${DEB_FILE}")"
    echo "==> DEB package created: ${DEB_FILE}"
else
    echo "[ERROR] DEB file not found"
    ls -la "${PROJECT_ROOT}/../"*.deb 2>/dev/null || echo "No .deb files found"
    exit 1
fi

# Step 8: Run lintian checks
echo "==> Running lintian checks"
if command -v lintian >/dev/null 2>&1; then
    lintian --suppress-tags embedded-library,hardening-no-pie,library-not-linked-against-libc \
        "${DEB_FILE}" || true
fi

# Cleanup build artifacts from parent directory
rm -f "${PROJECT_ROOT}/../vicinae_"*.buildinfo
rm -f "${PROJECT_ROOT}/../vicinae_"*.changes

echo ""
echo "==> Build completed successfully!"
echo "    Package: ${DEB_FILE}"
echo "    Size: $(du -h "${DEB_FILE}" | cut -f1)"
echo ""
echo "To install: sudo dpkg -i ${DEB_FILE}"
echo "To verify:  dpkg -c ${DEB_FILE}"
