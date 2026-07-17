#!/bin/sh

set -eu

version="3.7.2"
artifact="TVVLCKit-${version}-3e42ae47-79128878.tar.xz"
url="https://download.videolan.org/cocoapods/prod/${artifact}"
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_dir=$(dirname -- "$script_dir")
destination_dir="$repository_dir/Carthage/Build"
destination="$destination_dir/TVVLCKit.xcframework"

if [ -d "$destination" ]; then
    exit 0
fi

temporary_dir=$(mktemp -d "${TMPDIR:-/tmp}/prismedia-tvvlckit.XXXXXX")
trap 'rm -rf "$temporary_dir"' EXIT INT TERM

curl --fail --location --retry 2 --output "$temporary_dir/$artifact" "$url"
tar -xJf "$temporary_dir/$artifact" -C "$temporary_dir"
mkdir -p "$destination_dir"
cp -R "$temporary_dir/TVVLCKit-binary/TVVLCKit.xcframework" "$destination"
