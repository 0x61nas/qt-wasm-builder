# syntax=docker/dockerfile:1
# Qt WASM Builder — Alpine Linux
# Pinned to Alpine 3.23.4 (latest stable as of Jun 2026).
# Update the base tag when newer Alpine releases are available.
#
# Build:
#   docker build --build-arg VARIANT=singlethread  -t qt-wasm-builder:6.11.1-st .
#   docker build --build-arg VARIANT=multithread   -t qt-wasm-builder:6.11.1-mt  .
#
# Run (mount your project at /app):
#   docker run --rm -v $(pwd):/app qt-wasm-builder:6.11.1-st \
#     cmake -B build -S . -G Ninja
#
# Override Qt or emsdk version at build time:
#   docker build --build-arg QT_VER=6.11.3 --build-arg EMSDK_VER=4.0.9 ...

FROM alpine:3.24.0

# ------------------------------------------------------------------
# Build arguments — change these to pin different versions
# ------------------------------------------------------------------
ARG QT_VER=6.11.1
ARG EMSDK_VER=4.0.7
ARG VARIANT

# ------------------------------------------------------------------
# Environment variables
# QT_BASE_DIR / QMAKESPEC — consumed by Qt's cmake toolchain file
# EMSDK / EMSCRIPTEN     — consumed by emsdk_env.sh and build scripts
# ------------------------------------------------------------------
ENV QT_BASE_DIR=/opt/Qt/${QT_VER}/wasm_${VARIANT} \
    QMAKESPEC=/opt/Qt/${QT_VER}/wasm_${VARIANT}/mkspecs \
    EMSDK=/opt/emsdk \
    EMSCRIPTEN=/opt/emsdk/upstream/emscripten

# ------------------------------------------------------------------
# 1. System dependencies
# gcompat + libstdc++: glibc ABI layer for emsdk prebuilt binaries
#   (LLVM, binaryen, node).  Without this the prebuilts will fail on
#   musl-based Alpine.
# build-base, cmake, ninja: required to build Qt WASM projects
# python3, py3-pip: runtime for aqtinstall
# curl, git: download sources
# binaryen: wasm utilities
# ------------------------------------------------------------------
RUN apk add --no-cache \
    bash \
    build-base \
    7zip \
    cmake \
    ninja \
    curl \
    git \
    python3 \
    py3-pip \
    nodejs \
    gcompat \
    libstdc++ \
    qt6-qtbase-dev \
    qt6-qtsvg-dev \
    binaryen

# ------------------------------------------------------------------
# 1b. Download wabt prebuilt binaries (not packaged in Alpine)
#     Architecture is auto-detected via ARG TARGETARCH (buildx) or uname.
# ------------------------------------------------------------------
ARG TARGETARCH
RUN case "${TARGETARCH:-$(uname -m)}" in \
      x86_64|amd64) WABT_ARCH=x64 ;; \
      aarch64|arm64) WABT_ARCH=arm64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH:-$(uname -m)}" && exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/WebAssembly/wabt/releases/download/1.0.41/wabt-1.0.41-linux-${WABT_ARCH}.tar.gz" \
      | tar xz -C /usr/local --strip-components=1

# Alternative: build wabt from source (comment out above, uncomment below)
# RUN git clone --depth 1 --recursive https://github.com/WebAssembly/wabt.git /tmp/wabt \
#     && cmake -S /tmp/wabt -B /tmp/wabt/build \
#         -DCMAKE_BUILD_TYPE=Release \
#         -DBUILD_TESTS=OFF \
#         -DCMAKE_INSTALL_PREFIX=/usr/local \
#     && cmake --build /tmp/wabt/build -- -j"$(nproc)" \
#     && cmake --install /tmp/wabt/build \
#     && rm -rf /tmp/wabt

# ------------------------------------------------------------------
# 2. Install aqtinstall and download Qt for WASM
# --break-system-packages: required on Alpine ≥3.19 (PEP 668)
# --no-cache-dir: avoid storing pip cache
# -m qtcharts qtwebsockets: extra modules
# ------------------------------------------------------------------
RUN pip3 install --no-cache-dir --break-system-packages aqtinstall \
    && aqt install-qt all_os wasm "${QT_VER}" "wasm_${VARIANT}" \
        -O /opt/Qt \
        -m qtcharts qtwebsockets

# ------------------------------------------------------------------
# 3. Install emscripten SDK
# ------------------------------------------------------------------
RUN git clone --depth 1 --single-branch --branch "${EMSDK_VER}" \
        https://github.com/emscripten-core/emsdk.git /opt/emsdk \
    && cd /opt/emsdk \
    && ./emsdk install "${EMSDK_VER}" \
    && ./emsdk activate "${EMSDK_VER}" \
    && sed -i "s|NODE_JS = .*|NODE_JS = '/usr/bin/node'|" /opt/emsdk/.emscripten \
    && rm -rf /opt/emsdk/.git /opt/emsdk/zips /opt/emsdk/node

# ------------------------------------------------------------------
# 4. Build helper entrypoint
# ------------------------------------------------------------------
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /app
ENTRYPOINT ["entrypoint.sh"]
CMD ["/bin/sh"]
