#!/bin/sh

set -eu

repository_path="${CI_PRIMARY_REPOSITORY_PATH:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}"
platform="${CI_PRODUCT_PLATFORM:-}"

exec "$repository_path/Scripts/install-vlckit-release.sh" "$platform"
