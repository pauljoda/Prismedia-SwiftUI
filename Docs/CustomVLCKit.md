# Custom VLCKit builds

Prismedia maintains a narrow downstream build of
[VideoLAN VLCKit](https://code.videolan.org/videolan/VLCKit) 3.7.3. The source
patch, reproducible build script, release workflow, binary verification, and
published checksums all live in this repository.

The goal is not to fork VLCKit as a product. It is to make two compatibility
changes transparent and reproducible while they are needed by Prismedia and
other Apple-platform media clients.

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

Every immutable release contains:

| Asset | Architectures and environments |
| --- | --- |
| `MobileVLCKit.xcframework.zip` | iOS arm64 device; arm64/x86_64 Simulator |
| `VLCKit.xcframework.zip` | macOS arm64/x86_64 |
| `TVVLCKit.xcframework.zip` | tvOS arm64 device; arm64/x86_64 Simulator |

Each archive has a neighboring `.sha256` file. GitHub also records the archive
digest in the release asset metadata.

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

1. Clone the upstream VLCKit 3.7.3 tag into a temporary directory.
2. Apply `Scripts/Patches/TVVLCKit-EnableTrueHD.patch`.
3. Run the upstream build for the requested platform.
4. Verify the required MLP/TrueHD symbols and deployment-safe pipe fallback.
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
