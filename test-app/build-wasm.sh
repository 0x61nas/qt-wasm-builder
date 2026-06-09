#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="$SCRIPT_DIR/build/wasm"
OBJ_DIR="$SCRIPT_DIR/build/.wasm_obj"
BUILDER_IMAGE="${BUILDER_IMAGE:-qt-wasm-builder:test-st}"
BUILD_MODE="${1:-debug}"

# If not already inside the Docker container, re-invoke inside it
if [ ! -f "${QT_BASE_DIR:-}/lib/libQt6Core.a" ]; then
    if ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
        echo "Builder image '$BUILDER_IMAGE' not found. Build it first:"
        echo "  docker build -f Dockerfile.singlethread -t $BUILDER_IMAGE ."
        exit 1
    fi
    echo "Running WASM build inside Docker ($BUILDER_IMAGE)..."
    docker run --rm -v "$SCRIPT_DIR":/app "$BUILDER_IMAGE" \
        bash /app/build-wasm.sh "$BUILD_MODE"
    exit $?
fi

# --- Inside Docker container below ---
QT_WASM=$QT_BASE_DIR
EMCC="$(command -v emcc)" || { echo "ERROR: emcc not found"; exit 1; }
MOC="$(command -v moc || command -v moc6 || echo '/usr/lib/qt6/libexec/moc')"

echo "Using emcc: $EMCC"

case "$BUILD_MODE" in
    debug)
        OPT="-O0 -g"
        LTOPT="-O0"

        CXXFLAGS="-std=c++17 -fPIC $OPT"
        CXXFLAGS="$CXXFLAGS -I$QT_WASM/include"
        CXXFLAGS="$CXXFLAGS -I$QT_WASM/include/QtCore -I$QT_WASM/include/QtGui -I$QT_WASM/include/QtWidgets"
        CXXFLAGS="$CXXFLAGS -DQT_CORE_LIB -DQT_GUI_LIB -DQT_WIDGETS_LIB"
        CXXFLAGS="$CXXFLAGS -DQT_STATICPLUGIN"
        CXXFLAGS="$CXXFLAGS -s USE_ZLIB=1"

        LDFLAGS="-L$QT_WASM/lib"
        LDFLAGS="$LDFLAGS -L$QT_WASM/plugins/platforms"
        LDFLAGS="$LDFLAGS $LTOPT"
        LDFLAGS="$LDFLAGS -lQt6Core"
        LDFLAGS="$LDFLAGS -lQt6Widgets -lQt6Gui"
        LDFLAGS="$LDFLAGS -lQt6OpenGL"
        LDFLAGS="$LDFLAGS -lQt6BundledFreetype -lQt6BundledHarfbuzz"
        LDFLAGS="$LDFLAGS -lQt6BundledLibpng -lQt6BundledLibjpeg -lQt6BundledPcre2"
        LDFLAGS="$LDFLAGS -lQt6BundledZLIB"
        LDFLAGS="$LDFLAGS -s USE_ZLIB=1"
        LDFLAGS="$LDFLAGS -s INITIAL_MEMORY=50MB"
        LDFLAGS="$LDFLAGS -s MAXIMUM_MEMORY=4GB"
        LDFLAGS="$LDFLAGS -s ALLOW_MEMORY_GROWTH"
        LDFLAGS="$LDFLAGS -s MAX_WEBGL_VERSION=2"
        LDFLAGS="$LDFLAGS -s WASM_BIGINT=1"
        LDFLAGS="$LDFLAGS -s STACK_SIZE=5MB"
        LDFLAGS="$LDFLAGS -lembind -lidbfs.js -sFETCH -sASYNCIFY"
        ;;
    release)
        OPT="-Oz -flto=full"
        LTOPT="-Oz -flto=full"

        CXXFLAGS="-std=c++17 -fPIC $OPT -DNDEBUG"
        CXXFLAGS="$CXXFLAGS -I$QT_WASM/include"
        CXXFLAGS="$CXXFLAGS -I$QT_WASM/include/QtCore -I$QT_WASM/include/QtGui -I$QT_WASM/include/QtWidgets"
        CXXFLAGS="$CXXFLAGS -DQT_CORE_LIB -DQT_GUI_LIB -DQT_WIDGETS_LIB"
        CXXFLAGS="$CXXFLAGS -DQT_STATICPLUGIN"
        CXXFLAGS="$CXXFLAGS -s USE_ZLIB=1"

        LDFLAGS="-L$QT_WASM/lib"
        LDFLAGS="$LDFLAGS -L$QT_WASM/plugins/platforms"
        LDFLAGS="$LDFLAGS $LTOPT"
        LDFLAGS="$LDFLAGS -lQt6Core"
        LDFLAGS="$LDFLAGS -lQt6Widgets -lQt6Gui"
        LDFLAGS="$LDFLAGS -lQt6BundledFreetype -lQt6BundledHarfbuzz"
        LDFLAGS="$LDFLAGS -lQt6BundledLibpng -lQt6BundledLibjpeg -lQt6BundledPcre2"
        LDFLAGS="$LDFLAGS -lQt6BundledZLIB"
        LDFLAGS="$LDFLAGS -s USE_ZLIB=1"
        LDFLAGS="$LDFLAGS -s INITIAL_MEMORY=256MB"
        LDFLAGS="$LDFLAGS -s ALLOW_MEMORY_GROWTH"
        LDFLAGS="$LDFLAGS -s MAXIMUM_MEMORY=4GB"
        LDFLAGS="$LDFLAGS -s MAX_WEBGL_VERSION=2"
        LDFLAGS="$LDFLAGS -s WASM_BIGINT=1"
        LDFLAGS="$LDFLAGS -s STACK_SIZE=5MB"
        LDFLAGS="$LDFLAGS -s ASYNCIFY"
        LDFLAGS="$LDFLAGS -lembind -lidbfs.js -sFETCH"
        LDFLAGS="$LDFLAGS --closure 1"
        LDFLAGS="$LDFLAGS -s SUPPORT_ERRNO=0"
        ;;
    *)
        echo "Usage: $0 [debug|release]"
        exit 1
        ;;
esac

LDFLAGS="$LDFLAGS -s EXPORTED_FUNCTIONS=_main"
LDFLAGS="$LDFLAGS -s MODULARIZE=1 -s EXPORT_NAME=HelloWasm"
LDFLAGS="$LDFLAGS -s EXPORTED_RUNTIME_METHODS=specialHTMLTargets,ccall,UTF8ToString"

# Extract plugin objects from libqwasm.a and link them directly
QWASM_A="$QT_WASM/plugins/platforms/libqwasm.a"
mkdir -p "$OBJ_DIR/qwasm_objs"
"$(dirname "$EMCC")/llvm-ar" x "$QWASM_A" --output="$OBJ_DIR/qwasm_objs" 2>/dev/null || \
    ar x "$QWASM_A" --output="$OBJ_DIR/qwasm_objs" 2>/dev/null || \
    (cd "$OBJ_DIR/qwasm_objs" && ar x "$QWASM_A")
QWASM_OBJS=""
for obj in "$OBJ_DIR"/qwasm_objs/*.o; do
    QWASM_OBJS="$QWASM_OBJS $obj"
done

PLUGIN_INIT="$QT_WASM/plugins/platforms/objects-Release/QWasmIntegrationPlugin_init/QWasmIntegrationPlugin_init.cpp.o"
PLUGIN_RCC1="$QT_WASM/lib/objects-Release/QWasmIntegrationPlugin_resources_1/.qt/rcc/qrc_wasmfonts_init.cpp.o"
PLUGIN_RCC2="$QT_WASM/lib/objects-Release/QWasmIntegrationPlugin_resources_2/.qt/rcc/qrc_wasmwindow_init.cpp.o"

for f in "$PLUGIN_INIT" "$PLUGIN_RCC1" "$PLUGIN_RCC2"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing plugin file: $f" >&2
        exit 1
    fi
done

mkdir -p "$OUT_DIR" "$OBJ_DIR"

echo "Compiling..."
"$EMCC" $CXXFLAGS -I"$SCRIPT_DIR" -c "$SCRIPT_DIR/main.cpp" -o "$OBJ_DIR/main.o"

echo "Linking..."
"$EMCC" "$OBJ_DIR/main.o" $QWASM_OBJS "$PLUGIN_INIT" "$PLUGIN_RCC1" "$PLUGIN_RCC2" \
    -o "$OUT_DIR/hellowasm.js" $LDFLAGS

if [ "$BUILD_MODE" = "release" ]; then
    echo "Optimizing WASM..."
    wasm-strip "$OUT_DIR/hellowasm.wasm"
    wasm-opt -Oz \
      --enable-sign-ext \
      --strip-debug \
      --strip-producers \
      --dce \
      --duplicate-function-elimination \
      --merge-blocks \
      --merge-locals \
      --vacuum \
      --coalesce-locals \
      --rse \
      --optimize-instructions \
      --precompute-propagate \
      --reorder-locals \
      --remove-unused-module-elements \
      --converge \
      -o "$OUT_DIR/hellowasm.opt.wasm" \
      "$OUT_DIR/hellowasm.wasm"
    mv "$OUT_DIR/hellowasm.opt.wasm" "$OUT_DIR/hellowasm.wasm"
    wasm-opt -Oz \
      --strip \
      --enable-sign-ext \
      --converge \
      -o "$OUT_DIR/hellowasm.opt.wasm" \
      "$OUT_DIR/hellowasm.wasm"
    mv "$OUT_DIR/hellowasm.opt.wasm" "$OUT_DIR/hellowasm.wasm"
fi

cp "$QT_WASM/plugins/platforms/qtloader.js" "$OUT_DIR/"
cp "$QT_WASM/plugins/platforms/qtlogo.svg" "$OUT_DIR/"
cp "$SCRIPT_DIR/wasm/index.html" "$OUT_DIR/"

echo ""
echo "Done:"
echo "  $OUT_DIR/index.html"
echo "  $OUT_DIR/hellowasm.js"
echo "  $OUT_DIR/hellowasm.wasm"
echo "  $OUT_DIR/qtloader.js"
echo "  $OUT_DIR/qtlogo.svg"
echo ""
echo "Serve with: python3 -m http.server 8080 -d $OUT_DIR"
