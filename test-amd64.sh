#!/bin/bash
set -euo pipefail

VARIANT="${1:-singlethread}"
IMAGE="qt-wasm-builder:test-${VARIANT}-amd64"

echo "=== Building ${VARIANT} image for amd64 ==="
docker build --build-arg "VARIANT=${VARIANT}" -t "$IMAGE" .

echo ""
echo "=== Building test app ==="
BUILDER_IMAGE="$IMAGE" ./test-app/build-wasm.sh debug

echo ""
echo "=== Output ==="
ls -lh test-app/build/wasm/
