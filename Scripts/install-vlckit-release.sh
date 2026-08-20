#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
platform="${1:-${PRISMEDIA_VLCKIT_PLATFORM:-}}"

. "$script_dir/vlckit-binary-contract.sh"
. "$script_dir/vlckit-release-manifest.sh"

case "$platform" in
    iOS | ios | iphoneos | iphonesimulator) platform="ios" ;;
    macOS | macos | macosx) platform="macos" ;;
    tvOS | tvos | appletvos | appletvsimulator) platform="tvos" ;;
    *)
        echo "Usage: $0 ios|macos|tvos" >&2
        exit 2
        ;;
esac

prismedia_vlckit_release_configuration "$platform"

if [ "$PRISMEDIA_VLCKIT_SHA256" = "PENDING_RELEASE_SHA256" ]; then
    echo "The pinned VLCKit release has not finished publishing." >&2
    exit 1
fi

asset="$PRISMEDIA_VLCKIT_FRAMEWORK.xcframework.zip"
release_url="https://github.com/pauljoda/Prismedia-SwiftUI/releases/download/$PRISMEDIA_VLCKIT_RELEASE/$asset"
destination_dir="$repository_dir/Carthage/Build"
destination_framework="$destination_dir/$PRISMEDIA_VLCKIT_DESTINATION.xcframework"
receipt="$destination_dir/.$PRISMEDIA_VLCKIT_DESTINATION.release"
expected_receipt="$PRISMEDIA_VLCKIT_RELEASE $PRISMEDIA_VLCKIT_SHA256"

if [ -f "$receipt" ] \
    && [ "$(sed -n '1p' "$receipt")" = "$expected_receipt" ] \
    && prismedia_vlckit_framework_is_compatible "$platform" "$destination_framework"; then
    echo "Using verified $PRISMEDIA_VLCKIT_DESTINATION from $PRISMEDIA_VLCKIT_RELEASE"
    exit 0
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-vlckit-release.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT INT TERM HUP

archive="$temporary_dir/$asset"
unpacked="$temporary_dir/unpacked"
source_framework="$unpacked/$PRISMEDIA_VLCKIT_FRAMEWORK.xcframework"

echo "Downloading $PRISMEDIA_VLCKIT_FRAMEWORK for $platform from $PRISMEDIA_VLCKIT_RELEASE"
curl --fail --location --retry 3 --retry-all-errors --output "$archive" "$release_url"

actual_sha256=$(shasum -a 256 "$archive" | awk '{print $1}')
if [ "$actual_sha256" != "$PRISMEDIA_VLCKIT_SHA256" ]; then
    echo "Checksum mismatch for $asset" >&2
    echo "Expected: $PRISMEDIA_VLCKIT_SHA256" >&2
    echo "Actual:   $actual_sha256" >&2
    exit 1
fi

mkdir -p "$unpacked"
ditto -x -k "$archive" "$unpacked"

if [ ! -d "$source_framework" ]; then
    echo "$asset did not contain $PRISMEDIA_VLCKIT_FRAMEWORK.xcframework" >&2
    exit 1
fi

if ! prismedia_vlckit_framework_is_compatible "$platform" "$source_framework"; then
    echo "$asset failed Prismedia's $platform VLCKit binary contract" >&2
    exit 1
fi

mkdir -p "$destination_dir"
staged_framework="$destination_framework.staged.$$"
rm -rf "$staged_framework"
ditto "$source_framework" "$staged_framework"
rm -rf "$destination_framework"
mv "$staged_framework" "$destination_framework"
printf '%s\n' "$expected_receipt" > "$receipt"

echo "Installed verified $PRISMEDIA_VLCKIT_FRAMEWORK at $destination_framework"
