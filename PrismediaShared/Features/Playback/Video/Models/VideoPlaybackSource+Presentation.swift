import Foundation

extension VideoPlaybackSource {
    func playbackDisplayMetadata(
        delivery: VideoPlaybackDelivery
    ) -> VideoPlaybackDisplayMetadata? {
        guard let video = streams.first(where: {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.video) == .orderedSame
        }) else { return nil }
        let preservesSourceVideo = delivery != .transcode || transcoding?.isVideoDirect == true
        let dynamicRange = preservesSourceVideo ? video.playbackDynamicRange : .sdr
        let frameRate = video.averageFrameRate.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        return VideoPlaybackDisplayMetadata(
            dynamicRange: dynamicRange,
            frameRate: frameRate,
            width: video.width,
            height: video.height,
            codec: preservesSourceVideo ? video.codec : transcoding?.videoCodec,
            dolbyVisionProfile: dynamicRange == .dolbyVision ? video.dolbyVisionProfile : nil,
            bitDepth: preservesSourceVideo ? video.bitDepth : 8
        )
    }

    func playbackRenderer(
        delivery: VideoPlaybackDelivery,
        preferredEngine: VideoPlaybackEngine = .automatic
    ) -> VideoPlaybackRenderer {
        guard let metadata = playbackDisplayMetadata(delivery: delivery) else { return .native }
        return VideoPlaybackRendererPolicy.renderer(
            delivery: delivery,
            sourceContainer: container,
            dynamicRange: metadata.dynamicRange,
            bitDepth: metadata.bitDepth,
            supportsCompatibilityRenderer: VideoPlaybackRendererPolicy.platformSupportsCompatibilityRenderer,
            preferredEngine: preferredEngine
        )
    }

    var playbackAudioStreams: [VideoPlaybackStreamChoice] {
        streams.compactMap { stream in
            guard stream.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.audio) == .orderedSame
            else { return nil }
            let index = stream.index
            let title =
                stream.displayTitle
                ?? stream.language?.uppercased()
                ?? stream.codec?.uppercased()
                ?? "Audio \(index + 1)"
            return .init(
                index: index,
                title: title,
                isSelected: stream.isDefault
            )
        }
    }

    func playbackBadges(delivery: VideoPlaybackDelivery) -> [VideoPlaybackBadge] {
        if delivery == .transcode {
            return [
                deliveryBadge(delivery),
                transcodedVideoBadge,
                transcodedAudioBadge,
            ].compactMap { $0 }
        }
        let video = streams.first {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.video) == .orderedSame
        }
        let audioStreams = streams.filter {
            $0.type.caseInsensitiveCompare(PrismediaContractCodes.StreamKind.audio) == .orderedSame
        }
        let audio = audioStreams.first(where: \.isDefault) ?? audioStreams.first
        return [
            deliveryBadge(delivery),
            resolutionBadge(video),
            codecBadge(video),
            rangeBadge(video),
            audioBadge(audio),
        ].compactMap { $0 }
    }

    private var transcodedVideoBadge: VideoPlaybackBadge? {
        guard let codec = transcoding?.videoCodec.lowercased() else { return nil }
        return .init(label: videoCodecLabel(codec), tone: .neutral)
    }

    private var transcodedAudioBadge: VideoPlaybackBadge? {
        guard let codec = transcoding?.audioCodec.lowercased() else { return nil }
        return .init(label: audioCodecLabel(codec), tone: premiumAudioCodecs.contains(codec) ? .premium : .neutral)
    }

    private func deliveryBadge(_ delivery: VideoPlaybackDelivery) -> VideoPlaybackBadge {
        switch delivery {
        case .direct: .init(label: "Direct Play", systemImage: "play.rectangle", tone: .direct)
        case .remux: .init(label: "Direct Stream", systemImage: "dot.radiowaves.left.and.right", tone: .direct)
        case .transcode: .init(label: "Transcoding", systemImage: "cpu", tone: .transcode)
        }
    }

    private func resolutionBadge(_ stream: VideoPlaybackStream?) -> VideoPlaybackBadge? {
        guard let width = stream?.width, let height = stream?.height else { return nil }
        let label =
            width >= 3_800 || height >= 2_100
            ? "4K"
            : width >= 1_900 || height >= 1_050
                ? "1080p"
                : height >= 700 ? "720p" : "\(height)p"
        return .init(label: label, tone: .neutral)
    }

    private func codecBadge(_ stream: VideoPlaybackStream?) -> VideoPlaybackBadge? {
        guard let codec = stream?.codec?.lowercased() else { return nil }
        return .init(label: videoCodecLabel(codec), tone: .neutral)
    }

    private func rangeBadge(_ stream: VideoPlaybackStream?) -> VideoPlaybackBadge? {
        guard let range = stream?.videoRangeType?.uppercased(), range != "SDR" else { return nil }
        let label =
            switch range {
            case "DOVI": "Dolby Vision"
            case "HDR10PLUS": "HDR10+"
            default: range
            }
        return .init(label: label, systemImage: "sparkles", tone: .premium)
    }

    private func audioBadge(_ stream: VideoPlaybackStream?) -> VideoPlaybackBadge? {
        guard let codec = stream?.codec?.lowercased() else { return nil }
        let format = audioCodecLabel(codec)
        let layout: String? =
            switch stream?.channels {
            case 8: "7.1"
            case 6: "5.1"
            case 2: "Stereo"
            case let channels?: "\(channels)ch"
            case nil: nil
            }
        return .init(
            label: [format, layout].compactMap { $0 }.joined(separator: " "),
            tone: premiumAudioCodecs.contains(codec) ? .premium : .neutral
        )
    }

    private func videoCodecLabel(_ codec: String) -> String {
        switch codec {
        case "h264", "avc": "H.264"
        case "hevc", "h265": "HEVC"
        case "av1": "AV1"
        case "vp9": "VP9"
        default: codec.uppercased()
        }
    }

    private func audioCodecLabel(_ codec: String) -> String {
        switch codec {
        case "eac3": "E-AC-3"
        case "ac3": "AC-3"
        case "aac": "AAC"
        case "truehd": "TrueHD"
        case "dts": "DTS"
        default: codec.uppercased()
        }
    }

    private var premiumAudioCodecs: Set<String> { ["eac3", "ac3", "truehd", "dts"] }
}

extension VideoPlaybackStream {
    fileprivate var playbackDynamicRange: VideoPlaybackDynamicRange {
        let range = videoRangeType?.uppercased() ?? ""
        if range.contains("DOVI") { return .dolbyVision }
        if range.contains("HLG") { return .hlg }
        if range.contains("HDR") { return .hdr10 }
        let transfer = colorTransfer?.uppercased() ?? ""
        if transfer.contains("HLG") { return .hlg }
        if transfer.contains("2084") || transfer.contains("PQ") { return .hdr10 }
        return .sdr
    }
}
