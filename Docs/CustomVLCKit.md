# Custom VLCKit builds

Prismedia maintains narrow downstream builds of
[VideoLAN VLCKit](https://code.videolan.org/videolan/VLCKit). iOS and macOS use
VLCKit 3.7.3. tvOS uses VLCKit 4.0.0-a23 with VLC pinned to commit
`2cd8705589d3b125f236d1af695c3961fdcf6ca4`. The source patches, reproducible
build script, release workflow, and binary verification live in this
repository.

The goal is not to fork VLCKit as a product. It is to make the compatibility
changes below transparent and reproducible while Prismedia needs them.

## Why this build exists

### TrueHD and MLP decoding

VLCKit's `0003-Enable-System-DL.patch` disables FFmpeg's MLP demuxer, parser,
and decoder. MLP is also the codec family used by Dolby TrueHD, so those flags
prevent compatible TrueHD tracks from being decoded.

Prismedia's patch removes only those three disable flags. The bootstrap script
then inspects the produced binaries and requires both `_ff_mlp_decoder` and
`_ff_truehd_decoder` before accepting a build.

### Deployment-safe `pipe()` fallback

New Apple SDKs declare `pipe2()`, but the function is not available on every
older tvOS release supported by the framework. Autoconf sees the declaration
while cross-compiling and can produce a binary with an unavailable `pipe2()`
import.

The patch sets `ac_cv_func_pipe2=no`, forcing VLC's existing `pipe()` fallback.
The bootstrap script rejects any produced framework that still has `_pipe2` as
an undefined symbol.

### Dolby Vision Profile 5 direct play on tvOS

Dolby Vision Profile 5 stores a Dolby-specific base layer. It is not an SDR or
HDR10-compatible picture by itself, so presenting only the decoded HEVC planes
produces the characteristic purple or green image even when the file is valid.

The tvOS patch keeps VideoToolbox hardware decoding active, parses each frame's
Dolby Vision RPU, attaches that metadata to the hardware picture, and routes it
through VLC's existing libplacebo reshape filter. Apple TV's GLES texture bridge
cannot expose VLC's P010 surface in the form this path expects, so the dedicated
Profile 5 route requests full-range NV12 output before the RPU reshape. The
profile-specific VLC options are off by default and Prismedia enables them only
when probe metadata identifies Dolby Vision Profile 5.

The patch also fixes two VLC 4 tvOS integration defects exercised by this path:
the video view can receive its first renderer subview before its asynchronous
enable callback, and an OpenGL filter replacement could initialize the wrong
framebuffer relationship. Both fixes preserve VLC's existing behavior while
removing the assertion and duplicated or inverted renderer output.

Apple TV exposes this renderer as GLES 2.0 with GLSL 100. A separate libplacebo
patch selects a vector type that GLSL 100 accepts for Dolby Vision reshaping,
instead of emitting a boolean-vector `mix` overload that the platform compiler
rejects. The bootstrap script requires the compiled marker for this path in
both tvOS slices.

The result is still direct play: the server sends the original media bytes and
does not perform a video transcode. The Apple TV performs HEVC decoding and RPU
reshaping locally.

### Authenticated adaptive HLS

VLC's standard HTTP access applies `http-token`, but its adaptive HLS access
creates separate HTTP sources for child playlists and segments. The tvOS patch
forwards the inherited bearer token to those child requests. Prismedia supplies
the option only when a playback plan contains an `Authorization: Bearer` header,
so public and non-bearer playback behavior is unchanged.

### Deployment targets

The downstream build sets these explicit framework minimums:

| Platform | Minimum |
| --- | --- |
| iOS | 15.0 |
| tvOS | 15.0 |
| macOS | 12.0 |

Prismedia itself currently has newer deployment targets. The lower framework
minimums make the artifacts usable by other applications without changing
VLCKit's public API.

## Published artifacts

A complete release produced by the current workflow contains:

| Asset | Architectures and environments |
| --- | --- |
| `MobileVLCKit.xcframework.zip` | iOS arm64 device; arm64/x86_64 Simulator |
| `VLCKit.xcframework.zip` | macOS arm64/x86_64 |
| `VLCKitTV.xcframework.zip` | tvOS arm64 device; arm64/x86_64 Simulator |

Each archive has a neighboring `.sha256` file. GitHub also records the archive
digest in the release asset metadata. Consumers pin an immutable release and
its hashes; the repository does not silently retarget an existing release.

Download and verify an artifact before unpacking it:

```sh
VLCKIT_RELEASE=vlckit-3.7.3-prismedia.2
VLCKIT_ASSET=MobileVLCKit.xcframework.zip
VLCKIT_BASE=https://github.com/pauljoda/Prismedia-SwiftUI/releases/download/$VLCKIT_RELEASE

curl --fail --location --remote-name "$VLCKIT_BASE/$VLCKIT_ASSET"
curl --fail --location --remote-name "$VLCKIT_BASE/$VLCKIT_ASSET.sha256"
shasum -a 256 -c "$VLCKIT_ASSET.sha256"
ditto -x -k "$VLCKIT_ASSET" .
```

Use the immutable tag you intend to consume rather than a moving `latest` URL
in automation. Prismedia pins the three archive hashes directly in
`ci_scripts/ci_post_clone.sh`.

## Reproduce from source

Prerequisites are macOS, Xcode command-line tools, Git, and the build tools used
by upstream VLCKit.

Build every platform:

```sh
Scripts/bootstrap-vlckit.sh
```

Build one platform:

```sh
PRISMEDIA_VLCKIT_PLATFORM=ios Scripts/bootstrap-vlckit.sh
PRISMEDIA_VLCKIT_PLATFORM=macos Scripts/bootstrap-vlckit.sh
PRISMEDIA_VLCKIT_PLATFORM=tvos Scripts/bootstrap-vlckit.sh
```

The script performs the following steps:

1. Clone VLCKit 3.7.3 for iOS/macOS, or VLCKit 4.0.0-a23 and the pinned VLC 4
   commit for tvOS.
2. Apply `TVVLCKit-EnableTrueHD.patch` to the 3.7.3 wrapper, or VLCKit 4's
   pinned VLC compatibility series followed by the Profile 5, GLSL 100, and
   adaptive HTTP bearer patches to the pinned VLC 4 source.
3. Run the matching upstream build for the requested platform.
4. Verify MLP/TrueHD, the deployment-safe pipe fallback, the Profile 5 options,
   the GLSL 100 reshape marker, and adaptive bearer forwarding in both tvOS
   slices.
5. Install the accepted XCFramework under `Carthage/Build`.
6. Remove the temporary source checkout.

The GitHub workflow in `.github/workflows/build-vlckit-release.yml` repeats that
process independently for all three platforms on Xcode 26 runners. It also
checks the linked SDK with `vtool`, creates SHA-256 files, and publishes the
release only after every platform succeeds.

## Scope and support

These artifacts exist for Prismedia's playback requirements and are offered to
the community as a reproducible convenience. They are not official VideoLAN
builds and are not endorsed or supported by VideoLAN. General VLCKit issues
should be reproduced against upstream VLCKit before being reported there;
issues specific to this patch or these archives belong in this repository.

## Licensing

VLCKit is open-source software distributed by VideoLAN under the LGPL version
2.1 or later. Review [VideoLAN's VLCKit license information](https://www.videolan.org/projects/vlckit/)
and the upstream source's `COPYING` file before redistributing or embedding the
frameworks. Consumers are responsible for meeting the license requirements that
apply to their distribution. Prismedia's downstream patch is published here so
the corresponding modifications remain available and auditable.
