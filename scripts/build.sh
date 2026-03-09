#!/usr/bin/env bash
# Build SFZ module for Move Anything (ARM64)
#
# Builds sfizz from source via CMake, then compiles the plugin.
# Automatically uses Docker for cross-compilation if needed.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="move-anything-sfz-builder"

# Check if we need Docker
if [ -z "$CROSS_PREFIX" ] && [ ! -f "/.dockerenv" ]; then
    echo "=== SFZ Module Build (via Docker) ==="
    echo ""

    # Build Docker image if needed
    if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
        echo "Building Docker image (first time only)..."
        docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$REPO_ROOT"
        echo ""
    fi

    # Run build inside container
    echo "Running build..."
    docker run --rm \
        -v "$REPO_ROOT:/build" \
        -u "$(id -u):$(id -g)" \
        -w /build \
        "$IMAGE_NAME" \
        ./scripts/build.sh

    echo ""
    echo "=== Done ==="
    exit 0
fi

# === Actual build (runs in Docker or with cross-compiler) ===
CROSS_PREFIX="${CROSS_PREFIX:-aarch64-linux-gnu-}"

cd "$REPO_ROOT"

echo "=== Building SFZ Module ==="
echo "Cross prefix: $CROSS_PREFIX"

# Create build directories
mkdir -p build/sfizz-build
mkdir -p dist/sfz

# --- Step 1: Build sfizz as a static library ---
SFIZZ_DIR="src/dsp/third_party/sfizz"

if [ ! -f "build/sfizz-build/library/lib/libsfizz.a" ]; then
    echo ""
    echo "=== Building sfizz library ==="

    # Ensure submodule is initialized
    if [ ! -f "$SFIZZ_DIR/CMakeLists.txt" ]; then
        echo "Error: sfizz submodule not initialized."
        echo "Run: git submodule update --init --recursive"
        exit 1
    fi

    # Create CMake toolchain file for ARM64 cross-compilation
    cat > build/aarch64-toolchain.cmake << 'TOOLCHAIN_EOF'
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_FIND_ROOT_PATH /usr/aarch64-linux-gnu)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv8-a -mtune=cortex-a72")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv8-a -mtune=cortex-a72")
TOOLCHAIN_EOF

    cd build/sfizz-build

    cmake "../../$SFIZZ_DIR" \
        -DCMAKE_TOOLCHAIN_FILE=../aarch64-toolchain.cmake \
        -DCMAKE_BUILD_TYPE=Release \
        -DSFIZZ_JACK=OFF \
        -DSFIZZ_RENDER=OFF \
        -DSFIZZ_BENCHMARKS=OFF \
        -DSFIZZ_TESTS=OFF \
        -DSFIZZ_DEMOS=OFF \
        -DSFIZZ_DEVTOOLS=OFF \
        -DPLUGIN_LV2=OFF \
        -DPLUGIN_LV2_UI=OFF \
        -DPLUGIN_VST3=OFF \
        -DPLUGIN_AU=OFF \
        -DPLUGIN_PUREDATA=OFF \
        -DSFIZZ_SHARED=OFF \
        -DBUILD_SHARED_LIBS=OFF

    cmake --build . -j$(nproc)

    cd "$REPO_ROOT"
    echo "sfizz library built successfully"
fi

# All sfizz static libraries are in library/lib/
SFIZZ_LIB_DIR="build/sfizz-build/library/lib"

if [ ! -f "$SFIZZ_LIB_DIR/libsfizz.a" ]; then
    echo "Error: Could not find libsfizz.a in $SFIZZ_LIB_DIR"
    find build/sfizz-build -name "*.a" 2>/dev/null | head -20
    exit 1
fi

echo "Found sfizz libraries in: $SFIZZ_LIB_DIR"

# --- Step 2: Compile DSP plugin and link with sfizz ---
echo ""
echo "=== Compiling DSP plugin ==="

# Compile plugin as C, then link with C++ (sfizz is C++)
${CROSS_PREFIX}gcc -O3 -fPIC \
    -march=armv8-a -mtune=cortex-a72 \
    -DNDEBUG \
    -c src/dsp/sfz_plugin.c \
    -o build/sfz_plugin.o \
    -Isrc/dsp \
    -I"$SFIZZ_DIR/src"

# Link everything into dsp.so - use whole-archive for static libs
${CROSS_PREFIX}g++ -O3 -shared -fPIC \
    -march=armv8-a -mtune=cortex-a72 \
    build/sfz_plugin.o \
    -Wl,--whole-archive \
    "$SFIZZ_LIB_DIR"/libsfizz.a \
    "$SFIZZ_LIB_DIR"/libsfizz_internal.a \
    -Wl,--no-whole-archive \
    "$SFIZZ_LIB_DIR"/libsfizz_parser.a \
    "$SFIZZ_LIB_DIR"/libsfizz_messaging.a \
    "$SFIZZ_LIB_DIR"/libsfizz_import.a \
    "$SFIZZ_LIB_DIR"/libsfizz_kissfft.a \
    "$SFIZZ_LIB_DIR"/libsfizz_pugixml.a \
    "$SFIZZ_LIB_DIR"/libsfizz_cephes.a \
    "$SFIZZ_LIB_DIR"/libsfizz_cpuid.a \
    "$SFIZZ_LIB_DIR"/libsfizz_filesystem_impl.a \
    "$SFIZZ_LIB_DIR"/libsfizz_fmidi.a \
    "$SFIZZ_LIB_DIR"/libsfizz_hiir_polyphase_iir2designer.a \
    "$SFIZZ_LIB_DIR"/libsfizz_spin_mutex.a \
    "$SFIZZ_LIB_DIR"/libsfizz_spline.a \
    "$SFIZZ_LIB_DIR"/libsfizz_tunings.a \
    "$SFIZZ_LIB_DIR"/libst_audiofile.a \
    "$SFIZZ_LIB_DIR"/libst_audiofile_formats.a \
    "$SFIZZ_LIB_DIR"/libaiff.a \
    "$SFIZZ_LIB_DIR"/libwavpack.a \
    "$SFIZZ_LIB_DIR"/libabsl_*.a \
    -o build/dsp.so \
    -lm -lpthread -ldl -lstdc++ -latomic

echo "DSP plugin compiled"

# --- Step 3: Package ---
echo ""
echo "=== Packaging ==="

# Copy files to dist (use cat to avoid ExtFS deallocation issues with Docker)
cat src/module.json > dist/sfz/module.json
cat src/ui.js > dist/sfz/ui.js
cat build/dsp.so > dist/sfz/dsp.so
[ -f src/help.json ] && cat src/help.json > dist/sfz/help.json
chmod +x dist/sfz/dsp.so

# Create instruments directory for user SFZ instruments
mkdir -p dist/sfz/instruments

# Create tarball for release
cd dist
tar -czvf sfz-module.tar.gz sfz/
cd ..

echo ""
echo "=== Build Complete ==="
echo "Output: dist/sfz/"
echo "Tarball: dist/sfz-module.tar.gz"
echo ""
echo "To install on Move:"
echo "  ./scripts/install.sh"
