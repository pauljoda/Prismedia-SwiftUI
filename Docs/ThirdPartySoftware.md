# Third-Party Software

## VLCKit

The iOS, macOS, and tvOS compatibility players all link VLCKit 4.0.0-a23 from
VideoLAN with one exact pinned VLC 4 source revision and downstream patch set.
Prismedia's bootstrap applies the published patches under `Scripts/Patches` to
retain FFmpeg's MLP/TrueHD decoder, preserve and reshape Dolby Vision Profile 5
RPU metadata, and forward authenticated adaptive-stream requests. This lets the
compatibility player decode supported original tracks locally while keeping the
source video on the direct-play path.

VLCKit is
licensed under the GNU Lesser General Public License, version 2.1 or later.
Source and license materials are available from the
[VideoLAN VLCKit project](https://code.videolan.org/videolan/VLCKit).

The compatibility frameworks are dynamically linked and are used for sources
outside AVPlayer's supported container or media contract. Prismedia does not enable
TrueHD passthrough; VLCKit decodes it locally for the active platform audio route.
