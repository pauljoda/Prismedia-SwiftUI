# Third-Party Software

## VLCKit

The iOS, macOS, and tvOS compatibility players link source builds of
MobileVLCKit, VLCKit, and TVVLCKit 3.7.3 from VideoLAN. Prismedia's bootstrap
applies
`Scripts/Patches/TVVLCKit-EnableTrueHD.patch` to retain FFmpeg's MLP/TrueHD
decoder, which VideoLAN's prebuilt tvOS artifact excludes. This lets the
compatibility player decode the original lossless track locally while keeping
the source video on the direct-play path.

VLCKit is
licensed under the GNU Lesser General Public License, version 2.1 or later.
Source and license materials are available from the
[VideoLAN VLCKit project](https://code.videolan.org/videolan/VLCKit).

The compatibility frameworks are dynamically linked and are used for sources
outside AVPlayer's supported container or media contract. Prismedia does not enable
TrueHD passthrough; VLCKit decodes it locally for the active platform audio route.
