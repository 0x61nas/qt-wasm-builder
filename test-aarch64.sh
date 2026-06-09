#!/bin/sh
set -eu

VARIANT="${1:-singlethread}"
IMAGE="qt-wasm-builder:test-${VARIANT}-aarch64"

echo "=== Setting up QEMU binfmt ==="
docker run --privileged --rm tonistiigi/binfmt --install arm64

# Install docker buildx if not available
if ! docker buildx version >/dev/null 2>&1; then
    echo "=== Installing docker buildx ==="
    mkdir -p ~/.docker/cli-plugins
    curl -fsSL \
        "https://github.com/docker/buildx/releases/download/v0.20.0/buildx-v0.20.0.linux-amd64" \
        -o ~/.docker/cli-plugins/docker-buildx
    chmod +x ~/.docker/cli-plugins/docker-buildx
fi

echo ""
echo "=== Building ${VARIANT} image for arm64 (via QEMU) ==="
docker buildx build --platform linux/arm64 \
    -f "Dockerfile.${VARIANT}" \
    -t "$IMAGE" \
    --load .

echo ""
echo "=== Building test app ==="
BUILDER_IMAGE="$IMAGE" ./test-app/build-wasm.sh debug

echo ""
echo "=== Output ==="
ls -lh test-app/build/wasm/
