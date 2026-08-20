#!/bin/sh

set -eu

vlckit_version="4.0.0-a23"
vlc_revision="2cd8705589d3b125f236d1af695c3961fdcf6ca4"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
destination_dir="$repository_dir/Carthage/Build"
profile5_patch="$script_dir/Patches/VLCKit4-DolbyVisionProfile5.patch"
profile5_glsl100_patch="$script_dir/Patches/VLCKit4-DolbyVisionProfile5-GLSL100.patch"
adaptive_http_bearer_patch="$script_dir/Patches/VLCKit4-AdaptiveHTTPBearer.patch"
apple_xcconfig="$script_dir/VLCKit4-Apple.xcconfig"
requested_platform="${PRISMEDIA_VLCKIT_PLATFORM:-all}"

. "$script_dir/vlckit-binary-contract.sh"

case "$requested_platform" in
    all | ios | macos | tvos) ;;
    *)
        echo "Unsupported PRISMEDIA_VLCKIT_PLATFORM: $requested_platform" >&2
        exit 2
        ;;
esac

ios_destination="$destination_dir/VLCKitiOS.xcframework"
mac_destination="$destination_dir/VLCKitMac.xcframework"
tv_destination="$destination_dir/VLCKitTV.xcframework"

ios_ready=false
mac_ready=false
tv_ready=false

if [ "$requested_platform" != all ] && [ "$requested_platform" != ios ]; then
    ios_ready=true
elif prismedia_vlckit_framework_is_compatible ios "$ios_destination"; then
    ios_ready=true
fi

if [ "$requested_platform" != all ] && [ "$requested_platform" != macos ]; then
    mac_ready=true
elif prismedia_vlckit_framework_is_compatible macos "$mac_destination"; then
    mac_ready=true
fi

if [ "$requested_platform" != all ] && [ "$requested_platform" != tvos ]; then
    tv_ready=true
elif prismedia_vlckit_framework_is_compatible tvos "$tv_destination"; then
    tv_ready=true
fi

if [ "$ios_ready" = true ] && [ "$mac_ready" = true ] && [ "$tv_ready" = true ]; then
    exit 0
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-vlckit.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT INT TERM HUP

git clone --depth 1 --branch "$vlckit_version" \
    https://code.videolan.org/videolan/VLCKit.git "$temporary_dir/VLCKit"
mkdir "$temporary_dir/VLC"
git -C "$temporary_dir/VLC" init
git -C "$temporary_dir/VLC" remote add origin \
    https://code.videolan.org/videolan/vlc.git
git -C "$temporary_dir/VLC" fetch --depth 1 origin "$vlc_revision"
git -C "$temporary_dir/VLC" checkout --detach FETCH_HEAD

# External-source mode skips VLCKit's pinned VLC patch series. Apply that
# series first, then Prismedia's narrow patch set, for every Apple platform.
git -C "$temporary_dir/VLC" am \
    "$temporary_dir/VLCKit"/libvlc/patches/*.patch
git -C "$temporary_dir/VLC" apply "$profile5_patch"
git -C "$temporary_dir/VLC" apply "$profile5_glsl100_patch"
git -C "$temporary_dir/VLC" apply "$adaptive_http_bearer_patch"

# The wrapper still resolves headers and static libraries through libvlc/vlc
# when compiling from an external source checkout.
mkdir -p "$temporary_dir/VLCKit/libvlc"
ln -s "$temporary_dir/VLC" "$temporary_dir/VLCKit/libvlc/vlc"

install_framework() {
    source="$1"
    destination="$2"
    staged_destination="$destination.staged.$$"
    rm -rf "$staged_destination"
    ditto "$source" "$staged_destination"
    rm -rf "$destination"
    mv "$staged_destination" "$destination"
}

build_framework() {
    platform="$1"

    (
        cd "$temporary_dir/VLCKit"
        export ac_cv_func_pipe2=no
        export XCODE_XCCONFIG_FILE="$apple_xcconfig"

        case "$platform" in
            ios)
                if [ "${PRISMEDIA_VLCKIT_VERBOSE:-0}" = 1 ]; then
                    ./compileAndBuildVLCKit.sh -f -r -v -e "$temporary_dir/VLC"
                else
                    ./compileAndBuildVLCKit.sh -f -r -e "$temporary_dir/VLC"
                fi
                ;;
            macos)
                if [ "${PRISMEDIA_VLCKIT_VERBOSE:-0}" = 1 ]; then
                    ./compileAndBuildVLCKit.sh -x -f -r -v -e "$temporary_dir/VLC"
                else
                    ./compileAndBuildVLCKit.sh -x -f -r -e "$temporary_dir/VLC"
                fi
                ;;
            tvos)
                if [ "${PRISMEDIA_VLCKIT_VERBOSE:-0}" = 1 ]; then
                    ./compileAndBuildVLCKit.sh -t -f -r -v -e "$temporary_dir/VLC"
                else
                    ./compileAndBuildVLCKit.sh -t -f -r -e "$temporary_dir/VLC"
                fi
                ;;
        esac
    )
}

mkdir -p "$destination_dir"

if [ "$ios_ready" = false ]; then
    build_framework ios
    framework="$temporary_dir/VLCKit/build/iOS/VLCKit.xcframework"
    if ! prismedia_vlckit_framework_is_compatible ios "$framework"; then
        echo "VLCKitiOS failed Prismedia's patched VLCKit 4 binary contract." >&2
        exit 1
    fi
    install_framework "$framework" "$ios_destination"
fi

if [ "$mac_ready" = false ]; then
    build_framework macos
    framework="$temporary_dir/VLCKit/build/macOS/VLCKit.xcframework"
    if ! prismedia_vlckit_framework_is_compatible macos "$framework"; then
        echo "VLCKitMac failed Prismedia's patched VLCKit 4 binary contract." >&2
        exit 1
    fi
    install_framework "$framework" "$mac_destination"
fi

if [ "$tv_ready" = false ]; then
    build_framework tvos
    framework="$temporary_dir/VLCKit/build/tvOS/VLCKit.xcframework"
    if ! prismedia_vlckit_framework_is_compatible tvos "$framework"; then
        echo "VLCKitTV failed Prismedia's patched VLCKit 4 binary contract." >&2
        exit 1
    fi
    install_framework "$framework" "$tv_destination"
fi
