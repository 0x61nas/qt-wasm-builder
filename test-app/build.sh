#!/bin/sh
# Build the test app natively using host g++ and Qt6 (via pkg-config).
# Usage: ./build.sh [build-dir]

set -euo pipefail

BUILD_DIR="${1:-build/native}"
mkdir -p "$BUILD_DIR"

CXX="${CXX:-g++}"
MOC="${MOC:-$(command -v moc 2>/dev/null || echo /usr/lib/qt6/moc)}"
PKG_CONFIG="${PKG_CONFIG:-pkg-config}"

CXXFLAGS="-std=c++17 -fPIC $("$PKG_CONFIG" --cflags Qt6Core Qt6Widgets)"
LDFLAGS="$("$PKG_CONFIG" --libs Qt6Core Qt6Widgets)"

echo "=== Compiling ==="
"$CXX" $CXXFLAGS -c main.cpp -o "$BUILD_DIR/main.o"

echo "=== Linking ==="
"$CXX" $CXXFLAGS "$BUILD_DIR/main.o" $LDFLAGS -o "$BUILD_DIR/qt-wasm-test-native"

echo ""
echo "=== Output ==="
echo "Binary: $BUILD_DIR/qt-wasm-test-native"
echo ""
echo "Run: $BUILD_DIR/qt-wasm-test-native"
echo "Headless: QT_QPA_PLATFORM=offscreen $BUILD_DIR/qt-wasm-test-native"
