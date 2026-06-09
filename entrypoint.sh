#!/bin/sh
# entrypoint.sh - Qt WASM build environment activator
# Sources emscripten SDK and sets up Qt WASM cmake paths,
# then executes the user-provided command.

set -e

# emsdk_env.sh uses BASH_SOURCE to locate itself; provide it explicitly
# since we run under sh, not bash.
BASH_SOURCE=/opt/emsdk/emsdk_env.sh
export BASH_SOURCE
. /opt/emsdk/emsdk_env.sh

# Ensure Qt WASM cmake toolchain is discoverable
export CMAKE_PREFIX_PATH="${QT_BASE_DIR}:${CMAKE_PREFIX_PATH}"

exec "$@"
