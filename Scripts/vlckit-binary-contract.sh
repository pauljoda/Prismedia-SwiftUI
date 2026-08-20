#!/bin/sh

# Shared binary acceptance checks for source-built and released VLCKit artifacts.
# This file is sourced by the bootstrap, release installer, and build guard.

prismedia_vlckit_binary_is_compatible() {
    binary="$1"
    [ -f "$binary" ] \
        && strings "$binary" | grep -q -- 'videotoolbox-dovi-profile5' \
        && strings "$binary" | grep -q -- 'gl-dovi-profile5' \
        && strings "$binary" | grep -q -- 'glsl100-dovi-reshape' \
        && strings "$binary" | grep -q -- 'glsl120-rectangle-sampler-vflip' \
        && strings "$binary" | grep -q -- 'adaptive HTTP bearer forwarding enabled' \
        && ! strings "$binary" | grep -q -- '--disable-decoder=mlp' \
        && strings "$binary" | grep -q -- 'MLP (Meridian Lossless Packing)' \
        && strings "$binary" | grep -q -- 'TrueHD' \
        && strings "$binary" | grep -q -- 'ac_cv_func_pipe2=no' \
        && ! nm -u "$binary" | grep -q -- '_pipe2'
}

prismedia_vlckit_framework_is_compatible() {
    platform="$1"
    framework="$2"

    case "$platform" in
        ios)
            prismedia_vlckit_binary_is_compatible \
                "$framework/ios-arm64/VLCKit.framework/VLCKit" \
                && prismedia_vlckit_binary_is_compatible \
                    "$framework/ios-arm64_x86_64-simulator/VLCKit.framework/VLCKit"
            ;;
        macos)
            prismedia_vlckit_binary_is_compatible \
                "$framework/macos-arm64_x86_64/VLCKit.framework/Versions/A/VLCKit"
            ;;
        tvos)
            prismedia_vlckit_binary_is_compatible \
                "$framework/tvos-arm64/VLCKit.framework/VLCKit" \
                && prismedia_vlckit_binary_is_compatible \
                    "$framework/tvos-arm64_x86_64-simulator/VLCKit.framework/VLCKit"
            ;;
        *)
            echo "Unsupported VLCKit platform: $platform" >&2
            return 2
            ;;
    esac
}
