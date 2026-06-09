#!/bin/bash
# entrypoint.sh - Qt WASM build environment activator
# Sources emscripten SDK and sets up Qt WASM cmake paths,
# then executes the user-provided command.

set -e

# Activate emscripten SDK environment (sets PATH, EMSCRIPTEN, EMSDK, etc.)
. /opt/emsdk/emsdk_env.sh

# Ensure Qt WASM cmake toolchain is discoverable
export CMAKE_PREFIX_PATH="${QT_BASE_DIR}:${CMAKE_PREFIX_PATH}"

exec "$@"
