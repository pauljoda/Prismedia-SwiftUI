#!/bin/sh

set -eu

version="3.7.3"
vlckit4_version="4.0.0-a23"
vlc4_revision="2cd8705589d3b125f236d1af695c3961fdcf6ca4"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
destination_dir="$repository_dir/Carthage/Build"
lossless_patch="$script_dir/Patches/TVVLCKit-EnableTrueHD.patch"
profile5_patch="$script_dir/Patches/VLCKit4-tvOS-DolbyVisionProfile5.patch"
tvos_xcconfig="$script_dir/VLCKit4-tvOS.xcconfig"
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

tv_framework_is_compatible() {
    binary="$1"
    [ -f "$binary" ] \
        && strings "$binary" | grep -q -- 'videotoolbox-dovi-profile5' \
        && strings "$binary" | grep -q -- 'gl-dovi-profile5' \
        && ! strings "$binary" | grep -q -- '--disable-decoder=mlp' \
        && strings "$binary" | grep -q -- 'MLP (Meridian Lossless Packing)' \
        && strings "$binary" | grep -q -- 'TrueHD' \
        && strings "$binary" | grep -q -- 'ac_cv_func_pipe2=no' \
        && ! nm -u "$binary" | grep -q -- '_pipe2'
}

tv_framework_is_compatible_for_all_slices() {
    framework="$1"
    slice_count=0

    for binary in "$framework"/*/VLCKit.framework/VLCKit; do
        [ -f "$binary" ] || continue
        slice_count=$((slice_count + 1))
        tv_framework_is_compatible "$binary" || return 1
    done

    [ "$slice_count" -eq 2 ]
}

tv_destination="$destination_dir/VLCKitTV.xcframework"
ios_destination="$destination_dir/MobileVLCKit.xcframework"
mac_destination="$destination_dir/VLCKit.xcframework"

tv_ready=false
ios_ready=false
mac_ready=false

if [ "$requested_platform" != all ] && [ "$requested_platform" != tvos ]; then
    tv_ready=true
elif tv_framework_is_compatible_for_all_slices "$tv_destination"; then
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

if [ "$ios_ready" = false ] || [ "$mac_ready" = false ]; then
    git clone --depth 1 --branch "$version" \
        https://github.com/videolan/vlckit.git "$temporary_dir/VLCKit"
    patch -d "$temporary_dir/VLCKit" -p1 < "$lossless_patch"
fi

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
    git clone --depth 1 --branch "$vlckit4_version" \
        https://code.videolan.org/videolan/VLCKit.git "$temporary_dir/VLCKit4"
    mkdir "$temporary_dir/VLC4"
    git -C "$temporary_dir/VLC4" init
    git -C "$temporary_dir/VLC4" remote add origin \
        https://code.videolan.org/videolan/vlc.git
    git -C "$temporary_dir/VLC4" fetch --depth 1 origin "$vlc4_revision"
    git -C "$temporary_dir/VLC4" checkout --detach FETCH_HEAD
    # VLCKit's external-source mode skips the wrapper's own pinned VLC patch
    # series. Apply it explicitly before Prismedia's downstream renderer patch
    # so the wrapper APIs and static-link fixes match the selected VLCKit tag.
    git -C "$temporary_dir/VLC4" am \
        "$temporary_dir/VLCKit4"/libvlc/patches/*.patch
    git -C "$temporary_dir/VLC4" apply "$profile5_patch"
    # The -e option builds an external VLC checkout but the wrapper Xcode
    # project still resolves headers and static libraries through libvlc/vlc.
    # Link the pinned checkout at that expected path for archive packaging.
    mkdir -p "$temporary_dir/VLCKit4/libvlc"
    ln -s "$temporary_dir/VLC4" "$temporary_dir/VLCKit4/libvlc/vlc"

    (
        cd "$temporary_dir/VLCKit4"
        # Cross-compilation can detect the pipe2() declaration without its
        # older-tvOS availability. Keep VLC's deployment-safe pipe() fallback.
        export ac_cv_func_pipe2=no
        # VLCKit 4's archive helper passes IPHONEOS_DEPLOYMENT_TARGET even for
        # tvOS. An external xcconfig has command-line precedence and supplies
        # Prismedia's documented wrapper minimum on current Xcode releases.
        export XCODE_XCCONFIG_FILE="$tvos_xcconfig"
        ./compileAndBuildVLCKit.sh -t -f -r -e "$temporary_dir/VLC4"
    )
    framework="$temporary_dir/VLCKit4/build/tvOS/VLCKit.xcframework"
    if ! tv_framework_is_compatible_for_all_slices "$framework"; then
        echo "VLCKitTV is missing Profile 5 support, lossless decoders, or the safe pipe fallback." >&2
        exit 1
    fi
    install_framework "$framework" "$tv_destination"
fi
