#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
    echo "Usage: Scripts/set-version.sh MAJOR.MINOR.PATCH" >&2
    exit 2
fi

next_version=$1

if ! printf '%s\n' "$next_version" | grep -Eq '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$'; then
    echo "Version must be a strict MAJOR.MINOR.PATCH value without suffixes." >&2
    exit 2
fi

repository_path=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
version_config="$repository_path/Config/Version.xcconfig"
current_version=$(sed -n 's/^[[:space:]]*MARKETING_VERSION[[:space:]]*=[[:space:]]*\([^[:space:]]*\)[[:space:]]*$/\1/p' "$version_config")

if ! awk -F. -v current="$current_version" -v proposed="$next_version" '
    BEGIN {
        split(current, current_parts, ".")
        split(proposed, proposed_parts, ".")
        for (part = 1; part <= 3; part++) {
            if (proposed_parts[part] > current_parts[part]) exit 0
            if (proposed_parts[part] < current_parts[part]) exit 1
        }
        exit 1
    }
'; then
    echo "Version must increase from $current_version; received $next_version." >&2
    exit 2
fi

temporary_config=$(mktemp "$repository_path/Config/Version.xcconfig.XXXXXX")
trap 'rm -f "$temporary_config"' EXIT INT TERM HUP

printf '%s\n' \
    '// Native Prismedia release version. Update only through Scripts/set-version.sh.' \
    "MARKETING_VERSION = $next_version" \
    > "$temporary_config"
mv "$temporary_config" "$version_config"
trap - EXIT INT TERM HUP

"$repository_path/Scripts/check-version.sh"
