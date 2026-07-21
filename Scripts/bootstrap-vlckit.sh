#!/bin/sh

set -eu

version="3.7.3"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
destination_dir="$repository_dir/Carthage/Build"
lossless_patch="$script_dir/Patches/TVVLCKit-EnableTrueHD.patch"
requested_platform="${PRISMEDIA_VLCKIT_PLATFORM:-all}"

case "$requested_platform" in
    all | ios | macos | tvos) ;;
    *)
        echo "Unsupported PRISMEDIA_VLCKIT_PLATFORM: $requested_platform" >&2
        exit 2
        ;;
esac

framework_is_compatible() {
    binary="$1"
    [ -f "$binary" ] \
        && ! strings "$binary" | grep -q -- '--disable-decoder=mlp' \
        && nm "$binary" | grep -q -- '_ff_mlp_decoder' \
        && nm "$binary" | grep -q -- '_ff_truehd_decoder' \
        && ! nm -u "$binary" | grep -q -- '_pipe2'
}

tv_destination="$destination_dir/TVVLCKit.xcframework"
ios_destination="$destination_dir/MobileVLCKit.xcframework"
mac_destination="$destination_dir/VLCKit.xcframework"

tv_ready=false
ios_ready=false
mac_ready=false

if [ "$requested_platform" != all ] && [ "$requested_platform" != tvos ]; then
    tv_ready=true
elif framework_is_compatible "$tv_destination/tvos-arm64/TVVLCKit.framework/TVVLCKit" \
    && framework_is_compatible \
        "$tv_destination/tvos-arm64_x86_64-simulator/TVVLCKit.framework/TVVLCKit"; then
    tv_ready=true
fi
if [ "$requested_platform" != all ] && [ "$requested_platform" != ios ]; then
    ios_ready=true
elif framework_is_compatible "$ios_destination/ios-arm64/MobileVLCKit.framework/MobileVLCKit" \
    && framework_is_compatible \
        "$ios_destination/ios-arm64_x86_64-simulator/MobileVLCKit.framework/MobileVLCKit"; then
    ios_ready=true
fi
if [ "$requested_platform" != all ] && [ "$requested_platform" != macos ]; then
    mac_ready=true
elif framework_is_compatible "$mac_destination/macos-arm64_x86_64/VLCKit.framework/VLCKit"; then
    mac_ready=true
fi

if [ "$tv_ready" = true ] && [ "$ios_ready" = true ] && [ "$mac_ready" = true ]; then
    exit 0
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-vlckit.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT INT TERM HUP

git clone --depth 1 --branch "$version" https://github.com/videolan/vlckit.git "$temporary_dir/VLCKit"
patch -d "$temporary_dir/VLCKit" -p1 < "$lossless_patch"

install_framework() {
    source="$1"
    destination="$2"
    staged_destination="$destination.staged.$$"
    rm -rf "$staged_destination"
    cp -R "$source" "$staged_destination"
    rm -rf "$destination"
    mv "$staged_destination" "$destination"
}

mkdir -p "$destination_dir"

if [ "$ios_ready" = false ]; then
    (
        cd "$temporary_dir/VLCKit"
        ./buildMobileVLCKit.sh -f
    )
    framework="$temporary_dir/VLCKit/build/MobileVLCKit.xcframework"
    if ! framework_is_compatible "$framework/ios-arm64/MobileVLCKit.framework/MobileVLCKit" \
        || ! framework_is_compatible \
            "$framework/ios-arm64_x86_64-simulator/MobileVLCKit.framework/MobileVLCKit"; then
        echo "MobileVLCKit is missing required lossless decoders or imports unavailable pipe2()." >&2
        exit 1
    fi
    install_framework "$framework" "$ios_destination"
fi

if [ "$mac_ready" = false ]; then
    (
        cd "$temporary_dir/VLCKit"
        if [ "${PRISMEDIA_VLCKIT_VERBOSE:-0}" = 1 ]; then
            ./buildMobileVLCKit.sh -x -f -v
        else
            ./buildMobileVLCKit.sh -x -f
        fi
    )
    framework="$temporary_dir/VLCKit/build/VLCKit.xcframework"
    if ! framework_is_compatible "$framework/macos-arm64_x86_64/VLCKit.framework/VLCKit"; then
        echo "VLCKit is missing required lossless decoders or imports unavailable pipe2()." >&2
        exit 1
    fi
    install_framework "$framework" "$mac_destination"
fi

if [ "$tv_ready" = false ]; then
    (
        cd "$temporary_dir/VLCKit"
        ./buildMobileVLCKit.sh -t -f
    )
    framework="$temporary_dir/VLCKit/build/TVVLCKit.xcframework"
    if ! framework_is_compatible "$framework/tvos-arm64/TVVLCKit.framework/TVVLCKit" \
        || ! framework_is_compatible \
            "$framework/tvos-arm64_x86_64-simulator/TVVLCKit.framework/TVVLCKit"; then
        echo "TVVLCKit is missing required lossless decoders or imports unavailable pipe2()." >&2
        exit 1
    fi
    install_framework "$framework" "$tv_destination"
fi
