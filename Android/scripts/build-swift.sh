#!/usr/bin/env bash
#
#  build-swift.sh
#  EventPushStarterKit
#
#  Created by Komsit Chusangthong on 17/10/2569 BE.
#
# Cross-compiles SwiftCore for Android and copies the native libraries
# into a jniLibs folder (one sub-folder per ABI). Gradle runs it before
# every build; you can also run it by hand.
#
#   scripts/build-swift.sh [OUTPUT_DIR]
#
# Environment:
#   ABIS="arm64-v8a x86_64"   ABIs to build (default: arm64-v8a)
#   ANDROID_API=28            minimum API level (keep equal to minSdk)
#   SWIFT_CONFIG=release      release | debug
#   SWIFT=/path/to/swift      toolchain that matches the installed Swift SDK
#   ANDROID_NDK_HOME          NDK (default: newest in $ANDROID_HOME/ndk)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGE="$ROOT/SwiftCore"
OUTPUT="${1:-$ROOT/app/build/swift/jniLibs}"
ABIS="${ABIS:-arm64-v8a}"
API="${ANDROID_API:-28}"
CONFIG="${SWIFT_CONFIG:-release}"

# The Xcode toolchain cannot target Android: use the swift.org toolchain (swiftly).
if [[ -z "${SWIFT:-}" ]]; then
    if [[ -x "$HOME/.swiftly/bin/swift" ]]; then SWIFT="$HOME/.swiftly/bin/swift"; else SWIFT="swift"; fi
fi
if ! "$SWIFT" sdk list 2>/dev/null | grep -q android; then
    echo "error: no Swift SDK for Android found. See docs/SWIFT_ANDROID.md (Setup)." >&2
    exit 1
fi

ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    ANDROID_NDK_HOME="$(ls -d "$ANDROID_HOME"/ndk/* 2>/dev/null | sort -V | tail -1)"
fi
NDK_SYSROOT="$(ls -d "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/sysroot | head -1)"

for ABI in $ABIS; do
    case "$ABI" in
        arm64-v8a)   ARCH=aarch64; NDK_TRIPLE=aarch64-linux-android ;;
        x86_64)      ARCH=x86_64;  NDK_TRIPLE=x86_64-linux-android ;;
        armeabi-v7a) ARCH=armv7;   NDK_TRIPLE=arm-linux-androideabi ;;
        *) echo "error: unsupported ABI $ABI" >&2; exit 1 ;;
    esac
    SDK="$ARCH-unknown-linux-android$API"
    echo "▸ Swift → $ABI ($SDK, $CONFIG)"
    # --static-swift-stdlib: the Swift runtime is linked into our .so,
    # so the APK ships one Swift library instead of ~10.
    "$SWIFT" build --package-path "$PACKAGE" --swift-sdk "$SDK" -c "$CONFIG" \
        --static-swift-stdlib --product EventBridge
    BIN="$("$SWIFT" build --package-path "$PACKAGE" --swift-sdk "$SDK" -c "$CONFIG" --show-bin-path)"

    mkdir -p "$OUTPUT/$ABI"
    cp "$BIN/libEventBridge.so" "$OUTPUT/$ABI/"
    # The Swift runtime uses the NDK's shared C++ library.
    cp "$NDK_SYSROOT/usr/lib/$NDK_TRIPLE/libc++_shared.so" "$OUTPUT/$ABI/"
done
echo "✔ Native libraries in $OUTPUT"
