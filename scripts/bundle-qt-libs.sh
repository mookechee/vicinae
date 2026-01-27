#!/bin/bash
#
# Bundle Qt6 shared libraries and plugins into the DEB package staging area.
# This script copies the necessary Qt libraries from the build environment
# into the package so they don't need to be installed system-wide.
#
# Usage: bundle-qt-libs.sh <staging_dir>

set -euo pipefail

STAGING_DIR="${1:?Usage: $0 <staging_dir>}"
QT_LIB_DIR="${QT_LIB_DIR:-/usr/local/lib}"
QT_PLUGIN_DIR="${QT_PLUGIN_DIR:-/usr/local/plugins}"
BUNDLE_LIB_DIR="${STAGING_DIR}/usr/lib/vicinae"

echo "==> Bundling Qt libraries"
echo "    Qt lib dir: ${QT_LIB_DIR}"
echo "    Qt plugin dir: ${QT_PLUGIN_DIR}"
echo "    Target: ${BUNDLE_LIB_DIR}"

mkdir -p "${BUNDLE_LIB_DIR}"

# Qt6 core libraries to bundle
QT_LIBS=(
    libQt6Core.so
    libQt6Gui.so
    libQt6Widgets.so
    libQt6Network.so
    libQt6Svg.so
    libQt6DBus.so
    libQt6OpenGL.so
    libQt6OpenGLWidgets.so
    libQt6WaylandClient.so
    libQt6WaylandEglClientHwIntegration.so
    libQt6WlShellIntegration.so
    libQt6XcbQpa.so
    libQt6Sql.so
    libQt6Concurrent.so
    libicui18n.so
    libicuuc.so
    libicudata.so
)

for lib in "${QT_LIBS[@]}"; do
    # Find versioned .so files (e.g. libQt6Core.so.6.10.1, libQt6Core.so.6)
    found=false
    for f in "${QT_LIB_DIR}/${lib}"*; do
        if [ -f "$f" ] && [ ! -L "$f" ]; then
            cp "$f" "${BUNDLE_LIB_DIR}/"
            found=true
        elif [ -L "$f" ]; then
            cp -P "$f" "${BUNDLE_LIB_DIR}/"
            found=true
        fi
    done
    if [ "$found" = false ]; then
        echo "    [WARN] ${lib} not found in ${QT_LIB_DIR}, skipping"
    fi
done

# Bundle Qt plugins
QT_PLUGIN_TYPES=(
    platforms
    platformthemes
    wayland-shell-integration
    wayland-decoration-client
    wayland-graphics-integration-client
    xcbglintegrations
    sqldrivers
    imageformats
    iconengines
)

for plugin_type in "${QT_PLUGIN_TYPES[@]}"; do
    src="${QT_PLUGIN_DIR}/${plugin_type}"
    if [ -d "${src}" ]; then
        mkdir -p "${BUNDLE_LIB_DIR}/plugins/${plugin_type}"
        cp -r "${src}/"* "${BUNDLE_LIB_DIR}/plugins/${plugin_type}/"
    else
        echo "    [WARN] Plugin dir ${src} not found, skipping"
    fi
done

# Bundle Layer Shell Qt plugin
LAYER_SHELL_PLUGIN="/usr/local/lib/x86_64-linux-gnu/qt6/plugins/wayland-shell-integration/liblayer-shell.so"
if [ -f "${LAYER_SHELL_PLUGIN}" ]; then
    mkdir -p "${BUNDLE_LIB_DIR}/plugins/wayland-shell-integration"
    cp "${LAYER_SHELL_PLUGIN}" "${BUNDLE_LIB_DIR}/plugins/wayland-shell-integration/"
fi

# Bundle other required shared libs from /usr/local/lib that aren't in system repos
EXTRA_LIBS=(
    libqalculate.so
    libLayerShellQtInterface.so
    libfcitx5-qt6-input-context-plugin.so
)

for lib in "${EXTRA_LIBS[@]}"; do
    for search_dir in /usr/local/lib /usr/local/lib/x86_64-linux-gnu; do
        for f in "${search_dir}/${lib}"*; do
            if [ -f "$f" ] && [ ! -L "$f" ]; then
                cp "$f" "${BUNDLE_LIB_DIR}/"
            elif [ -L "$f" ]; then
                cp -P "$f" "${BUNDLE_LIB_DIR}/"
            fi
        done
    done
done

# Bundle fcitx5 Qt plugin
FCITX5_QT_PLUGIN="/usr/local/lib/x86_64-linux-gnu/qt6/plugins/platforminputcontexts"
if [ -d "${FCITX5_QT_PLUGIN}" ]; then
    mkdir -p "${BUNDLE_LIB_DIR}/plugins/platforminputcontexts"
    cp -r "${FCITX5_QT_PLUGIN}/"* "${BUNDLE_LIB_DIR}/plugins/platforminputcontexts/"
fi

# Bundle GCC runtime libraries (libstdc++ from custom GCC build)
GCC_LIB_DIR="/opt/gcc/lib64"
if [ -d "${GCC_LIB_DIR}" ]; then
    for lib in libstdc++.so libgcc_s.so; do
        for f in "${GCC_LIB_DIR}/${lib}"*; do
            if [ -f "$f" ] && [ ! -L "$f" ]; then
                cp "$f" "${BUNDLE_LIB_DIR}/"
            elif [ -L "$f" ]; then
                cp -P "$f" "${BUNDLE_LIB_DIR}/"
            fi
        done
    done
fi

# Create ld.so.conf.d entry for bundled libraries
mkdir -p "${STAGING_DIR}/etc/ld.so.conf.d"
echo "/usr/lib/vicinae" > "${STAGING_DIR}/etc/ld.so.conf.d/vicinae.conf"

# Create a qt.conf for the binary to find plugins
mkdir -p "${STAGING_DIR}/usr/bin"
cat > "${STAGING_DIR}/usr/bin/qt.conf" <<'QTCONF'
[Paths]
Plugins = ../lib/vicinae/plugins
Libraries = ../lib/vicinae
QTCONF

echo "==> Qt libraries bundled successfully"
echo "    Total size: $(du -sh "${BUNDLE_LIB_DIR}" | cut -f1)"
