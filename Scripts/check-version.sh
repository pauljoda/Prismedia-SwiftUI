#!/bin/sh

set -eu

repository_path=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version_config="$repository_path/Config/Version.xcconfig"
project_path="$repository_path/Prismedia.xcodeproj"

if [ ! -f "$version_config" ]; then
    echo "Missing native version source: $version_config" >&2
    exit 1
fi

version=$(sed -n 's/^[[:space:]]*MARKETING_VERSION[[:space:]]*=[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$version_config")

if ! printf '%s\n' "$version" | grep -Eq '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)([.](0|[1-9][0-9]*))?$'; then
    echo "Config/Version.xcconfig must contain one MAJOR.MINOR or MAJOR.MINOR.PATCH version." >&2
    exit 1
fi

for target in PrismediaiOS PrismediaMac PrismediaTV; do
    for configuration in Debug Release; do
        resolved_version=$(
            xcodebuild \
                -project "$project_path" \
                -target "$target" \
                -configuration "$configuration" \
                -showBuildSettings 2>/dev/null \
                | sed -n 's/^[[:space:]]*MARKETING_VERSION = \(.*\)$/\1/p' \
                | head -n 1
        )

        if [ "$resolved_version" != "$version" ]; then
            echo "$target $configuration resolves MARKETING_VERSION=$resolved_version; expected $version." >&2
            exit 1
        fi
    done
done

echo "Native app version $version is aligned across iOS, macOS, and tvOS."
