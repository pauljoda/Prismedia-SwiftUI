#!/bin/sh

set -eu

version="3.7.3"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
destination_dir="$repository_dir/Carthage/Build"
destination="$destination_dir/TVVLCKit.xcframework"
lossless_patch="$script_dir/Patches/TVVLCKit-EnableTrueHD.patch"
device_binary="$destination/tvos-arm64/TVVLCKit.framework/TVVLCKit"
simulator_binary="$destination/tvos-arm64_x86_64-simulator/TVVLCKit.framework/TVVLCKit"

has_mlp_decoder() {
    binary="$1"
    [ -f "$binary" ] \
        && ! strings "$binary" | grep -q -- '--disable-decoder=mlp' \
        && nm "$binary" | grep -q -- '_ff_mlp_decoder' \
        && nm "$binary" | grep -q -- '_ff_truehd_decoder'
}

if has_mlp_decoder "$device_binary" && has_mlp_decoder "$simulator_binary"; then
    exit 0
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-tvvlckit.XXXXXX")
staged_destination="$destination.staged.$$"
trap 'rm -rf "$temporary_dir" "$staged_destination"' EXIT INT TERM HUP

git clone --depth 1 --branch "$version" https://github.com/videolan/vlckit.git "$temporary_dir/VLCKit"
patch -d "$temporary_dir/VLCKit" -p1 < "$lossless_patch"

(
    cd "$temporary_dir/VLCKit"
    ./buildMobileVLCKit.sh -t -f
)

framework="$temporary_dir/VLCKit/build/TVVLCKit.xcframework"
built_device_binary="$framework/tvos-arm64/TVVLCKit.framework/TVVLCKit"
built_simulator_binary="$framework/tvos-arm64_x86_64-simulator/TVVLCKit.framework/TVVLCKit"
if ! has_mlp_decoder "$built_device_binary" || ! has_mlp_decoder "$built_simulator_binary"; then
    echo "TVVLCKit was built without the required MLP/TrueHD decoder." >&2
    exit 1
fi

mkdir -p "$destination_dir"
rm -rf "$staged_destination"
cp -R "$framework" "$staged_destination"
rm -rf "$destination"
mv "$staged_destination" "$destination"
