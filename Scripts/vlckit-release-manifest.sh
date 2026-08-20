#!/bin/sh

# Immutable release coordinates. Archive hashes are filled only after GitHub's
# release workflow publishes and the downloaded artifacts are independently
# verified.

prismedia_vlckit_release_configuration() {
    platform="$1"
    PRISMEDIA_VLCKIT_RELEASE="vlckit-4.0.0-a23-prismedia.2"

    case "$platform" in
        ios)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitiOS"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitiOS"
            PRISMEDIA_VLCKIT_SHA256="b547a4c9c929d73066aa10f6202cb8f3c829aaff0bc3e5dcb01448684868a49c"
            ;;
        macos)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitMac"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitMac"
            PRISMEDIA_VLCKIT_SHA256="624d02b177c0103f007f49c4a02f89cf52a7209bf4be11255cb4a5f3db2cf90d"
            ;;
        tvos)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitTV"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitTV"
            PRISMEDIA_VLCKIT_SHA256="de94ba52198eb8d729bdc9eb363d7eb9dc5859ea75243baf30d49cae66e44f0a"
            ;;
        *)
            echo "Unsupported VLCKit platform: $platform" >&2
            return 2
            ;;
    esac

}
