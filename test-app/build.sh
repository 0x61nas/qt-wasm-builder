#!/bin/bash
# build.sh - Build the test Qt WASM app using the docker image
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILDER_IMAGE="${BUILDER_IMAGE:-qt-wasm-builder:test-st}"
BUILD_DIR="$SCRIPT_DIR/build"
BUILD_MODE="${1:-debug}"

# If not already inside the Docker container, re-invoke inside it
if [ ! -f /opt/emsdk/emsdk_env.sh ]; then
    echo "Running build inside Docker ($BUILDER_IMAGE)..."
    docker run --rm -v "$SCRIPT_DIR":/app "$BUILDER_IMAGE" \
        bash /app/build.sh "$BUILD_MODE"
    exit $?
fi

# --- Inside Docker container below ---
# The entrypoint already sourced emsdk_env.sh and set CMAKE_PREFIX_PATH

case "$BUILD_MODE" in
    debug)
        CMAKE_BUILD_TYPE=Debug
        ;;
    release)
        CMAKE_BUILD_TYPE=Release
        ;;
    *)
        echo "Usage: $0 [debug|release]"
        exit 1
        ;;
esac

echo "Configuring with CMake..."
cmake -B "$BUILD_DIR" -S "$SCRIPT_DIR" \
    -DCMAKE_TOOLCHAIN_FILE="${QT_BASE_DIR}/lib/cmake/Qt6/qt.toolchain.cmake" \
    -G Ninja \
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"

echo "Building..."
cmake --build "$BUILD_DIR"

echo "Copying WASM runtime files..."
cp "$BUILD_DIR/hellowasm.js" "$BUILD_DIR/hellowasm.wasm" "$BUILD_DIR/hellowasm.html" "$SCRIPT_DIR/wasm/" 2>/dev/null || true
cp "${QT_BASE_DIR}/plugins/platforms/qtloader.js" "$SCRIPT_DIR/wasm/" 2>/dev/null || true
cp "${QT_BASE_DIR}/plugins/platforms/qtlogo.svg" "$SCRIPT_DIR/wasm/" 2>/dev/null || true

echo ""
echo "Done! Output in $SCRIPT_DIR/wasm/"
echo "Serve with: cd wasm && python3 -m http.server 8080"
