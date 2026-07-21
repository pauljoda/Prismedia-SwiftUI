#!/bin/sh

set -eu

release_tag="vlckit-3.7.3-prismedia.2"
repository_path="${CI_PRIMARY_REPOSITORY_PATH:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
platform="${CI_PRODUCT_PLATFORM:-}"

case "$platform" in
    iOS | ios | iphoneos | iphonesimulator)
        framework="MobileVLCKit"
        expected_sha256="4e792590843e33bbd422d72f3b0aff616684dc0beddc67e3cd4535e84bd804a9"
        ;;
    macOS | macos | macosx)
        framework="VLCKit"
        expected_sha256="8484dc28c0c48aa76269121591f8f3342c1bbe44497a2c53675aa36e7774e101"
        ;;
    tvOS | tvos | appletvos | appletvsimulator)
        framework="TVVLCKit"
        expected_sha256="4f106dfb8e5d7f49bf199716434b24556a128b44ae63e6bbbc0767986d6ee88a"
        ;;
    *)
        echo "Unsupported CI_PRODUCT_PLATFORM: ${platform:-<empty>}" >&2
        exit 2
        ;;
esac

asset="$framework.xcframework.zip"
release_url="https://github.com/pauljoda/Prismedia-SwiftUI/releases/download/$release_tag/$asset"
temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-xcode-cloud.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT INT TERM HUP

archive="$temporary_dir/$asset"
unpacked="$temporary_dir/unpacked"

echo "Downloading $framework for $platform from $release_tag"
curl --fail --location --retry 3 --retry-all-errors --output "$archive" "$release_url"

actual_sha256=$(shasum -a 256 "$archive" | awk '{print $1}')
if [ "$actual_sha256" != "$expected_sha256" ]; then
    echo "Checksum mismatch for $asset" >&2
    echo "Expected: $expected_sha256" >&2
    echo "Actual:   $actual_sha256" >&2
    exit 1
fi

mkdir -p "$unpacked"
ditto -x -k "$archive" "$unpacked"

source_framework="$unpacked/$framework.xcframework"
destination_dir="$repository_path/Carthage/Build"
destination_framework="$destination_dir/$framework.xcframework"

if [ ! -d "$source_framework" ]; then
    echo "$asset did not contain $framework.xcframework" >&2
    exit 1
fi

mkdir -p "$destination_dir"
rm -rf "$destination_framework"
ditto "$source_framework" "$destination_framework"

echo "Installed verified $framework at $destination_framework"
