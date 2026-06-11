# Qt WASM Docker

Production-ready Qt WASM builder Docker images based on Alpine Linux, with full tooling for building complex Qt WebAssembly applications.

## Features

- **Two variants**: `wasm_singlethread` and `wasm_multithread`
- **Qt 6.11.1** for WASM with extra modules: qtcharts, qtwebsockets, qtdeclarative, qtsvg, qttools
- **Emscripten SDK 4.0.7** — the version Qt 6.11 targets
- **Alpine Linux 3.23.4** base — small, secure, musl-based
- **Host Qt tools** from Alpine's `qt6-qtbase-dev` (moc, rcc, uic)
- **wasm-opt** from binaryen for WebAssembly optimization
- **wabt** prebuilt binaries (wat2wasm, wasm2wat, wasm-objdump, etc.)
- **Build helper entrypoint** — sources emsdk, sets `CMAKE_PREFIX_PATH`
- **Multi-arch**: published for `linux/amd64` and `linux/arm64`

## Variants

| Variant | Qt Arch | Use Case |
|---|---|---|
| `singlethread` | `wasm_singlethread` | Standard WASM apps |
| `multithread` | `wasm_multithread` | Apps needing pthreads/WASM threads |

## Pre-built Images

Images are published to both Docker Hub and GitHub Container Registry.

### Docker Hub

```bash
docker pull anaselgarhy/qt-wasm-builder:singlethread
docker pull anaselgarhy/qt-wasm-builder:multithread
```

### GitHub Container Registry

```bash
docker pull ghcr.io/0x61nas/qt-wasm-builder:singlethread
docker pull ghcr.io/0x61nas/qt-wasm-builder:multithread
```

### Tag Scheme

Tags follow the format: `<variant>`, `<variant>-<sha>`, `<variant>-v<semver>`, or `<variant>-<schedule>`.

## Manual Build

### Prerequisites

- Docker with BuildKit support (Docker 20.10+)

### Build singlethread variant

```bash
docker build --build-arg VARIANT=singlethread -t qt-wasm-builder:singlethread .
```

### Build multithread variant

```bash
docker build --build-arg VARIANT=multithread -t qt-wasm-builder:multithread .
```

### Override versions

```bash
docker build \
  --build-arg VARIANT=singlethread \
  --build-arg QT_VER=6.11.3 \
  --build-arg EMSDK_VER=4.0.9 \
  -t qt-wasm-builder:custom .
```

### Build for arm64

```bash
docker run --privileged --rm tonistiigi/binfmt --install arm64
docker buildx build --platform linux/arm64 \
  --build-arg VARIANT=singlethread \
  -t qt-wasm-builder:singlethread-arm64 \
  --load .
```

## Usage

### Run a CMake build

```bash
docker run --rm -v $(pwd):/app qt-wasm-builder:singlethread \
  cmake -B build -S . -G Ninja
```

### Compile directly with emcc

```bash
docker run --rm -v $(pwd):/app qt-wasm-builder:singlethread \
  emcc main.cpp -o output.js -s WASM=1
```

### Use the included test app

```bash
# Build and test on amd64
./test-amd64.sh

# Build and test on arm64 (requires QEMU)
./test-aarch64.sh
```

## Architecture

| Component | Details |
|---|---|
| **Base OS** | Alpine Linux 3.23.4 (musl-based) |
| **emsdk** | v4.0.7, installed at `/opt/emsdk` |
| **Qt WASM** | v6.11.1, installed via aqtinstall at `/opt/Qt/6.11.1/wasm_*` |
| **Host Qt tools** | Alpine `qt6-qtbase-dev` package (moc, rcc, uic live at `/usr/lib/qt6/libexec/`) |
| **wasm-opt** | From Alpine `binaryen` package |
| **wabt** | Prebuilt binaries from GitHub releases (x86_64 `/usr/local/bin/`) |
| **Entrypoint** | `/usr/local/bin/entrypoint.sh` — sources emsdk, sets `CMAKE_PREFIX_PATH` |
| **Working dir** | `/app` |
| **glibc compat** | `gcompat` + `libstdc++` provides glibc ABI for emsdk's prebuilt LLVM/node/binaryen on musl |

### Platform Support

- **linux/amd64**: Fully supported, tested with every build
- **linux/arm64**: Supported via QEMU emulation in CI. Emscripten 4.0.7+ provides native arm64 Linux prebuilts

### Version Compatibility

Qt 6.11 targets emscripten 4.0.7. The prebuilt Qt WASM binaries from aqtinstall are compiled against that emscripten version. Running with a different emscripten version may cause ABI issues — this image pins both to matching versions.

Host Qt tools (moc/rcc/uic) come from Alpine's `qt6-qtbase-dev` package. A minor version mismatch with the WASM target version is acceptable for code-generation tools.

## Source Code

- **GitHub**: https://github.com/0x61nas/qt-wasm-builder
- **GitLab**: https://gitlab.com/anelgarhy/qt-wasm-builder
- **Codeberg**: https://codeberg.org/0x61nas/qt-wasm-builder
- **Disroot**: https://git.disroot.org/anas/qt-wasm-builder
- **Codefloe**: https://codefloe.com/anas/qt-wasm-builder
- **GitGud**: https://gitgud.io/anelgarhy/qt-wasm-builder
- **Tangled**: https://tangled.org/anas.tngl.sh/qt-wasm-builder

## License

This project is provided under the MIT license. Qt itself is licensed under LGPLv3 / GPLv3 / commercial licenses. Emscripten is MIT-licensed.

