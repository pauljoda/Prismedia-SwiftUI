#!/bin/sh

# Immutable release coordinates. Archive hashes are filled only after GitHub's
# release workflow publishes and the downloaded artifacts are independently
# verified.

prismedia_vlckit_release_configuration() {
    platform="$1"
    PRISMEDIA_VLCKIT_RELEASE="vlckit-4.0.0-a23-prismedia.3"

    case "$platform" in
        ios)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitiOS"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitiOS"
            PRISMEDIA_VLCKIT_SHA256="45b76a9152a9762137cc71032540ce9149480b3ee8c95bb4a12ae9c3f2e7a82b"
            ;;
        macos)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitMac"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitMac"
            PRISMEDIA_VLCKIT_SHA256="140ac67a3a1d228d3b7fbe49612410679513ea8865f8ee048101b0b8fb1e6efa"
            ;;
        tvos)
            PRISMEDIA_VLCKIT_FRAMEWORK="VLCKitTV"
            PRISMEDIA_VLCKIT_DESTINATION="VLCKitTV"
            PRISMEDIA_VLCKIT_SHA256="0643601f07fc090e25ea86792d19dac1bd1d5e12c385ea412697e6a897446296"
            ;;
        *)
            echo "Unsupported VLCKit platform: $platform" >&2
            return 2
            ;;
    esac

}
