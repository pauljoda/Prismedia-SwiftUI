import CoreMedia
import VideoToolbox

struct AppleDeviceProfile: Encodable {
    let directPlayProfiles: [AppleDirectPlayProfile]
    let transcodingProfiles: [AppleTranscodingProfile]
    let codecProfiles: [AppleCodecProfile]

    enum CodingKeys: String, CodingKey {
        case directPlayProfiles = "DirectPlayProfiles"
        case transcodingProfiles = "TranscodingProfiles"
        case codecProfiles = "CodecProfiles"
    }

    static var current: Self {
        make(
            supportsCompatibilityRenderer: VideoPlaybackRendererPolicy.platformSupportsCompatibilityRenderer
        )
    }

    static func make(supportsCompatibilityRenderer: Bool) -> Self {
        let modernVideoCodecs = [
            "h264", supports(.hevc) ? "hevc" : nil, supports(.av1) ? "av1" : nil, supports(.vp9) ? "vp9" : nil,
        ]
        .compactMap { $0 }.joined(separator: ",")
        let movVideoCodecs = ["h264", supports(.hevc) ? "hevc" : nil, "mpeg4", "mjpeg"]
            .compactMap { $0 }.joined(separator: ",")
        let transportStreamVideoCodecs = ["h264", supports(.hevc) ? "hevc" : nil]
            .compactMap { $0 }.joined(separator: ",")
        let transcodingVideoCodecs = [
            supports(.av1) ? "av1" : nil, supports(.hevc) ? "hevc" : nil, "h264", "mpeg4",
        ]
        .compactMap { $0 }.joined(separator: ",")
        var directPlayProfiles: [AppleDirectPlayProfile] = [
            .init(
                type: "Video", container: "mp4,m4v", videoCodec: modernVideoCodecs,
                audioCodec: "aac,ac3,eac3,alac,flac"
            ),
            .init(
                type: "Video", container: "mov", videoCodec: movVideoCodecs,
                audioCodec: "aac,ac3,eac3,alac,mp3,pcm_s16be,pcm_s16le,pcm_s24be,pcm_s24le"
            ),
            .init(
                type: "Video", container: "mpegts,ts", videoCodec: transportStreamVideoCodecs,
                audioCodec: "aac,ac3,eac3,mp3"
            ),
        ]
        if supportsCompatibilityRenderer {
            directPlayProfiles.append(
                .init(
                    type: "Video",
                    container: "mkv,matroska",
                    videoCodec: modernVideoCodecs,
                    audioCodec: "aac,ac3,eac3,truehd,mlp,dts,dtshd,alac,flac,mp3,opus,vorbis"
                )
            )
        }
        return Self(
            directPlayProfiles: directPlayProfiles,
            transcodingProfiles: [
                .init(
                    type: "Video",
                    container: "mp4",
                    protocolName: "hls",
                    videoCodec: transcodingVideoCodecs,
                    audioCodec: "aac,ac3,eac3,alac,flac",
                    context: "Streaming",
                    breakOnNonKeyFrames: true,
                    maxAudioChannels: "8",
                    minSegments: 2,
                    enableSubtitlesInManifest: true
                )
            ],
            codecProfiles: codecProfiles
        )
    }

    static var supportedVideoRangeTypes: [String] {
        var ranges = ["SDR", "DOVIWithSDR"]
        if supports(.hevc) {
            ranges += [
                "HDR10", "HDR10Plus", "HLG", "DOVIWithHLG", "DOVIWithHDR10",
                "DOVIWithHDR10Plus", "DOVIWithELHDR10Plus",
            ]
        }
        if supports(.dolbyVision) { ranges.append("DOVI") }
        return ranges
    }

    private static var codecProfiles: [AppleCodecProfile] {
        var profiles = [
            AppleCodecProfile(
                type: "Video",
                codec: "h264",
                conditions: baseConditions(
                    profiles: "high|main|baseline|constrained baseline",
                    maximumLevel: "80"
                ) + [
                    videoBitDepthCondition(maximum: 8),
                    videoRangeCondition(values: "SDR|DOVIWithSDR"),
                ]
            )
        ]
        if supports(.hevc) {
            profiles.append(
                AppleCodecProfile(
                    type: "Video",
                    codec: "hevc",
                    conditions: baseConditions(profiles: "main|main 10", maximumLevel: "175")
                        + [
                            .init(
                                condition: "EqualsAny",
                                property: "VideoCodecTag",
                                value: "hvc1",
                                isRequired: false
                            ),
                            videoBitDepthCondition(maximum: 10),
                            videoRangeCondition(values: supportedVideoRangeTypes.joined(separator: "|")),
                        ]
                )
            )
        }
        if supports(.av1) {
            profiles.append(
                AppleCodecProfile(
                    type: "Video",
                    codec: "av1",
                    conditions: frameLayoutConditions
                        + [
                            videoBitDepthCondition(maximum: 10),
                            videoRangeCondition(values: supportedVideoRangeTypes.joined(separator: "|")),
                        ]
                )
            )
        }
        if supports(.vp9) {
            profiles.append(
                AppleCodecProfile(
                    type: "Video",
                    codec: "vp9",
                    conditions: frameLayoutConditions + [videoBitDepthCondition(maximum: 10)]
                )
            )
        }
        return profiles
    }

    private static func baseConditions(profiles: String, maximumLevel: String) -> [AppleProfileCondition] {
        frameLayoutConditions + [
            .init(condition: "EqualsAny", property: "VideoProfile", value: profiles, isRequired: false),
            .init(condition: "LessThanEqual", property: "VideoLevel", value: maximumLevel, isRequired: false),
        ]
    }

    private static var frameLayoutConditions: [AppleProfileCondition] {
        [
            .init(condition: "NotEquals", property: "IsAnamorphic", value: "true", isRequired: false),
            .init(condition: "NotEquals", property: "IsInterlaced", value: "true", isRequired: false),
        ]
    }

    private static func videoRangeCondition(values: String) -> AppleProfileCondition {
        .init(condition: "EqualsAny", property: "VideoRangeType", value: values, isRequired: false)
    }

    private static func videoBitDepthCondition(maximum: Int) -> AppleProfileCondition {
        .init(
            condition: "LessThanEqual",
            property: "VideoBitDepth",
            value: String(maximum),
            isRequired: true
        )
    }

    private enum Codec { case hevc, av1, vp9, dolbyVision }
    private static func supports(_ codec: Codec) -> Bool {
        switch codec {
        case .hevc: VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
        case .av1: VTIsHardwareDecodeSupported(kCMVideoCodecType_AV1)
        case .vp9: VTIsHardwareDecodeSupported(kCMVideoCodecType_VP9)
        case .dolbyVision: VTIsHardwareDecodeSupported(kCMVideoCodecType_DolbyVisionHEVC)
        }
    }
}
