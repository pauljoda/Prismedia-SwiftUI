#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
platform="${1:-}"

. "$script_dir/vlckit-binary-contract.sh"
. "$script_dir/vlckit-release-manifest.sh"

case "$platform" in
    ios | macos | tvos) ;;
    *)
        echo "Usage: $0 ios|macos|tvos" >&2
        exit 2
        ;;
esac

prismedia_vlckit_release_configuration "$platform"
framework="$repository_dir/Carthage/Build/$PRISMEDIA_VLCKIT_DESTINATION.xcframework"
receipt="$repository_dir/Carthage/Build/.$PRISMEDIA_VLCKIT_DESTINATION.release"
expected_receipt="$PRISMEDIA_VLCKIT_RELEASE $PRISMEDIA_VLCKIT_SHA256"

if [ ! -f "$receipt" ] || [ "$(sed -n '1p' "$receipt")" != "$expected_receipt" ]; then
    echo "$framework is not pinned to $PRISMEDIA_VLCKIT_RELEASE." >&2
    echo "Run Scripts/install-vlckit-release.sh $platform and rebuild." >&2
    exit 1
fi

if ! prismedia_vlckit_framework_is_compatible "$platform" "$framework"; then
    echo "$framework is missing or incompatible." >&2
    echo "Run Scripts/install-vlckit-release.sh $platform and rebuild." >&2
    exit 1
fi

echo "Verified Prismedia's pinned $platform VLCKit binary contract"
