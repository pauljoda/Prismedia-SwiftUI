import SwiftUI

struct EntityDetailPresentation {
    let detail: EntityDetail
    let canEditMetadata: Bool
    let identifyActionLabel: String
    let identifyActionSystemImage: String
    let acquisitionStatus: AcquisitionStatus?
    let mediaDetail: EntityDetail?
    let mediaThumbnail: EntityThumbnail?

    init(
        detail: EntityDetail,
        canEditMetadata: Bool = false,
        identifyActionLabel: String = "Identify",
        identifyActionSystemImage: String = "doc.viewfinder",
        acquisitionStatus: AcquisitionStatus? = nil,
        mediaDetail: EntityDetail? = nil,
        mediaThumbnail: EntityThumbnail? = nil
    ) {
        self.detail = detail
        self.canEditMetadata = canEditMetadata
        self.identifyActionLabel = identifyActionLabel
        self.identifyActionSystemImage = identifyActionSystemImage
        self.acquisitionStatus = acquisitionStatus
        self.mediaDetail = mediaDetail
        self.mediaThumbnail = mediaThumbnail
    }

    var sections: [EntityDetailSection] {
        sections(mainTitle: "Main", mainSystemImage: "square.text.square")
    }

    func sections(
        mainTitle: String,
        mainSystemImage: String
    ) -> [EntityDetailSection] {
        var values = [section(.details, mainTitle, mainSystemImage)]
        if !metadata.isEmpty || hasMetadataCapability || canEditMetadata {
            values.append(section(.metadata, "Metadata", "info.circle"))
        }
        if !markers.isEmpty {
            values.append(section(.markers, "Markers", "bookmark", count: markers.count))
        }
        if !subtitles.isEmpty {
            values.append(section(.transcript, "Transcript", "captions.bubble", count: subtitles.count))
        }
        if supportsAcquisition {
            values.append(section(.acquisition, "Acquisition", "arrow.down.circle"))
        }
        return values
    }

    var actions: [EntityDetailAction] {
        var values: [EntityDetailAction] = []
        if let flags = flagCapability {
            values.append(
                action(
                    .favorite, flags.isFavorite == true ? "Favorite" : "Add to favorites", "heart",
                    selected: flags.isFavorite == true))
            values.append(
                action(
                    .organized, flags.isOrganized == true ? "Organized" : "Mark organized", "checkmark.circle",
                    selected: flags.isOrganized == true))
        }
        values.append(action(.edit, "Edit", "pencil"))
        if detail.hasSourceMedia, flagCapability?.isWanted != true {
            values.append(
                action(
                    .identify,
                    identifyActionLabel,
                    identifyActionSystemImage
                )
            )
        }
        if let primaryAction { values.append(primaryAction) }
        return values
    }

    var primaryActions: [EntityDetailAction] {
        actions.filter(\.isPrimary)
    }

    var modificationActions: [EntityDetailAction] {
        actions.filter { !$0.isPrimary }
    }

    var images: EntityImagesCapability? {
        detail.capability()
    }

    var description: String? {
        let capability: EntityDescriptionCapability? = detail.capability()
        let text = capability?.value.trimmingCharacters(in: .whitespacesAndNewlines)
        return text?.isEmpty == false ? text : nil
    }

    var rating: Int? {
        detail.capability(EntityRatingCapability.self)?.value
    }

    var hasRatingCapability: Bool {
        detail.capability(EntityRatingCapability.self) != nil
    }

    var flagCapability: EntityFlagsCapability? {
        detail.capability()
    }

    var flagItems: [EntityDetailFlagItem] {
        guard let flags = flagCapability else { return [] }
        return [
            flags.isFavorite == true
                ? .init(title: "Favorite", systemImage: "heart.fill", tone: .accent) : nil,
            flags.isNsfw == true
                ? .init(title: "NSFW", systemImage: "eye.slash.fill", tone: .destructive) : nil,
            wantedFlagItem(flags),
        ].compactMap { $0 }
    }

    var mediaBadges: [VideoPlaybackBadge] {
        var badges: [VideoPlaybackBadge] = []
        if let technical: EntityTechnicalCapability = (mediaDetail ?? detail).capability() {
            if let width = technical.width, let height = technical.height {
                badges.append(
                    .init(
                        label: Self.resolutionLabel(width: width, height: height),
                        systemImage: "rectangle.inset.filled",
                        tone: .neutral
                    )
                )
            }
            if let codec = technical.codec?.trimmingCharacters(in: .whitespacesAndNewlines),
                !codec.isEmpty
            {
                badges.append(.init(label: codec.uppercased(), systemImage: "film", tone: .neutral))
            }
            if let format = technical.container ?? technical.format,
                !format.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                badges.append(.init(label: format.uppercased(), systemImage: "shippingbox", tone: .neutral))
            }
        }

        badges.append(contentsOf: thumbnailMediaBadges(excluding: Set(badges.map(\.label))))
        return badges
    }

    private func thumbnailMediaBadges(excluding existingLabels: Set<String>) -> [VideoPlaybackBadge] {
        guard let thumbnail = mediaThumbnail
            ?? detail.childrenByKind
                .first(where: { $0.kind == .video })?
                .entities
                .sorted(by: Self.sourceOrder)
                .first
        else { return [] }

        return thumbnail.meta.compactMap { item in
            let icon = item.icon.lowercased()
            guard ["resolution", "codec", "format", "video"].contains(icon),
                !existingLabels.contains(item.label)
            else { return nil }
            return VideoPlaybackBadge(
                label: item.label,
                systemImage: icon == "resolution" ? "rectangle.inset.filled" : "film",
                tone: .neutral
            )
        }
    }

    private func wantedFlagItem(_ flags: EntityFlagsCapability) -> EntityDetailFlagItem? {
        guard flags.isWanted == true else { return nil }
        guard let acquisitionStatus else {
            return .init(
                title: "Wanted",
                systemImage: "arrow.down.circle.fill",
                tone: .info
            )
        }
        let statusPresentation = AcquisitionStatusPresentationPolicy.compactPresentation(
            for: acquisitionStatus
        )
        return .init(
            title: statusPresentation.label,
            systemImage: statusPresentation.systemImage,
            tone: .acquisition(statusPresentation.tone)
        )
    }

    var markers: [EntityMarker] {
        detail.capability(EntityItemsCapability<EntityMarker>.self)?.items ?? []
    }

    var subtitles: [EntitySubtitle] {
        detail.capability(EntitySubtitlesCapability.self)?.items ?? []
    }

    var heroPath: String? {
        images?.items
            .first { $0.kind == "backdrop" && Self.nonemptyPath($0.path) != nil }
            .flatMap { Self.nonemptyPath($0.path) }
    }

    var posterPath: String? {
        let roles = ["poster", "thumbnail", "cover"]
        let itemPath = images?.items
            .first { roles.contains($0.kind) && Self.nonemptyPath($0.path) != nil }
            .flatMap { Self.nonemptyPath($0.path) }
        return itemPath
            ?? Self.nonemptyPath(images?.coverURL)
            ?? Self.nonemptyPath(images?.thumbnail2xURL)
            ?? Self.nonemptyPath(images?.thumbnailURL)
    }

    var systemImage: String {
        switch detail.kind {
        case .audio, .audioLibrary, .audioTrack, .musicArtist: return "music.note"
        case .book, .bookVolume, .bookChapter, .bookPage, .bookAuthor: return "book.closed"
        case .person: return "person.crop.rectangle"
        case .studio: return "building.2"
        case .tag: return "tag"
        case .gallery, .image: return "photo"
        default: return "film"
        }
    }

    var metadata: [EntityDetailMetadataItem] {
        var items: [EntityDetailMetadataItem] = []
        for capability in detail.capabilities {
            switch capability {
            case .classification(let value):
                if let classification = value.value {
                    items.append(
                        .init(label: "Classification", value: classification, systemImage: "rectangle.3.group"))
                }
            case .rating(let rating):
                items.append(
                    .init(
                        label: "Rating",
                        value: rating.value.map { "\($0) / 5" } ?? "Not rated",
                        systemImage: "star.fill"
                    )
                )
            case .flags(let flags):
                if let isFavorite = flags.isFavorite {
                    items.append(
                        .init(
                            label: "Favorite",
                            value: Self.yesNo(isFavorite),
                            systemImage: isFavorite ? "heart.fill" : "heart"
                        )
                    )
                }
                if let isOrganized = flags.isOrganized {
                    items.append(
                        .init(
                            label: "Organized",
                            value: Self.yesNo(isOrganized),
                            systemImage: isOrganized ? "checkmark.circle.fill" : "circle"
                        )
                    )
                }
                if let isWanted = flags.isWanted {
                    items.append(
                        .init(
                            label: "Wanted",
                            value: Self.yesNo(isWanted),
                            systemImage: isWanted ? "arrow.down.circle.fill" : "arrow.down.circle"
                        )
                    )
                }
                if let isNsfw = flags.isNsfw {
                    items.append(
                        .init(
                            label: "Sensitive Content",
                            value: Self.yesNo(isNsfw),
                            systemImage: isNsfw ? "eye.slash.fill" : "eye"
                        )
                    )
                }
            case .dates(let dates):
                items += EntityDateMilestonePolicy.sorted(dates.items).map {
                    .init(label: EntityDateMilestonePolicy.label(for: $0), value: $0.value, systemImage: "calendar")
                }
            case .playback(let playback):
                items.append(.init(label: "Plays", value: String(playback.playCount), systemImage: "play.circle"))
                if playback.resumeSeconds > 0 {
                    items.append(
                        .init(
                            label: "Resume", value: Self.duration(playback.resumeSeconds),
                            systemImage: "clock.arrow.circlepath"))
                }
            case .position(let positions):
                items += positions.items.prefix(3).map {
                    .init(label: Self.titleCase($0.code), value: $0.label ?? String($0.value), systemImage: "number")
                }
            case .progress(let progress):
                if progress.total > 0 {
                    let percent = Int((Double(progress.index) / Double(progress.total) * 100).rounded())
                    items.append(.init(label: "Progress", value: "\(percent)%", systemImage: "chart.bar.fill"))
                }
            case .stats(let stats):
                items += stats.items.prefix(4).map {
                    .init(label: Self.titleCase($0.code), value: $0.value, systemImage: "chart.bar.xaxis")
                }
            case .technical(let technical):
                if let duration = technical.duration {
                    items.append(.init(label: "Duration", value: duration, systemImage: "clock"))
                }
                if let width = technical.width, let height = technical.height {
                    items.append(
                        .init(
                            label: "Resolution",
                            value: "\(width) × \(height) (\(Self.resolutionLabel(width: width, height: height)))",
                            systemImage: "rectangle"
                        )
                    )
                }
                if let frameRate = technical.frameRate, frameRate.isFinite, frameRate > 0 {
                    items.append(
                        .init(
                            label: "Frame Rate",
                            value: "\(frameRate.formatted(.number.precision(.fractionLength(0...2)))) fps",
                            systemImage: "speedometer"
                        )
                    )
                }
                if let bitRate = technical.bitRate, bitRate > 0 {
                    items.append(
                        .init(
                            label: "Bit Rate",
                            value: Self.bitRate(bitRate),
                            systemImage: "waveform.path"
                        )
                    )
                }
                if let sampleRate = technical.sampleRate, sampleRate > 0 {
                    items.append(
                        .init(
                            label: "Sample Rate",
                            value: "\((Double(sampleRate) / 1_000).formatted(.number.precision(.fractionLength(0...1)))) kHz",
                            systemImage: "waveform"
                        )
                    )
                }
                if let channels = technical.channels, channels > 0 {
                    items.append(
                        .init(
                            label: "Channels",
                            value: Self.channelLabel(channels),
                            systemImage: "speaker.wave.3"
                        )
                    )
                }
                if let codec = technical.codec {
                    items.append(.init(label: "Codec", value: codec.uppercased(), systemImage: "film"))
                }
                if let container = technical.container {
                    items.append(.init(label: "Container", value: container.uppercased(), systemImage: "shippingbox"))
                }
                if let format = technical.format,
                    format.caseInsensitiveCompare(technical.container ?? "") != .orderedSame
                {
                    items.append(.init(label: "Format", value: format.uppercased(), systemImage: "doc"))
                }
            case .providerIdentity(let provider):
                items.append(
                    .init(
                        label: "Provider",
                        value: provider.pluginID,
                        systemImage: "network",
                        url: provider.url.flatMap(Self.externalURL)
                    )
                )
                items.append(
                    .init(label: provider.identityNamespace, value: provider.identityValue, systemImage: "number"))
            case .lifetime(let lifetime):
                if let start = lifetime.start {
                    items.append(
                        .init(
                            label: lifetime.label ?? "Started",
                            value: start.value,
                            systemImage: "calendar.badge.clock"
                        )
                    )
                }
                if let end = lifetime.end {
                    items.append(
                        .init(
                            label: "Ended",
                            value: end.value,
                            systemImage: "calendar.badge.checkmark"
                        )
                    )
                }
            case .fingerprints(let fingerprints):
                items += fingerprints.items.prefix(3).map {
                    .init(
                        label: Self.titleCase($0.algorithm),
                        value: $0.value,
                        systemImage: "touchid"
                    )
                }
            case .source(let sources):
                items += sources.items.prefix(3).map {
                    .init(label: Self.titleCase($0.code), value: $0.value, systemImage: "externaldrive")
                }
            case .links(let links):
                items += links.externalIDs.prefix(3).map {
                    .init(
                        label: $0.provider,
                        value: $0.value,
                        systemImage: "link",
                        url: $0.url.flatMap(Self.externalURL)
                    )
                }
                items += links.urls.prefix(2).map {
                    .init(
                        label: $0.label ?? "Link",
                        value: $0.value,
                        systemImage: "link",
                        url: Self.externalURL($0.value)
                    )
                }
            default: continue
            }
        }
        return items
    }

    func creditSubtitle(for personID: UUID) -> String? {
        guard let metadata = detail.creditMetadata.first(where: { $0.personID == personID }) else {
            return nil
        }
        return EntityDetailCreditSubtitlePolicy.subtitle(for: metadata)
    }

    private var supportsAcquisition: Bool {
        detail.kind != .collection
            && (detail.hasSourceMedia || flagCapability?.isWanted != nil)
    }

    private var hasMetadataCapability: Bool {
        detail.capabilities.contains {
            switch $0 {
            case .classification, .dates, .fingerprints, .lifetime, .links, .providerIdentity, .source, .stats,
                .technical:
                return true
            default: return false
            }
        }
    }

    private var primaryAction: EntityDetailAction? {
        if PlayableVideoResolver.videoID(in: detail) != nil {
            let resumeSeconds = max(
                0,
                detail.capability(EntityPlaybackCapability.self)?.resumeSeconds ?? 0
            )
            return action(
                resumeSeconds > 0 ? .resume : .play,
                resumeSeconds > 0
                    ? "Resume \(VideoPlaybackPresentation.clockTime(resumeSeconds))"
                    : "Play",
                "play.fill",
                primary: true
            )
        }
        let hasProgress = detail.capability(EntityProgressCapability.self)?.currentEntityID != nil
        switch detail.kind {
        case .book:
            switch BookReaderFormatPolicy.route(for: detail.bookFormat) {
            case .comic, .pdf, .epub:
                break
            case .unavailable, .unsupported:
                return nil
            }
            return action(
                hasProgress ? .resume : .read, hasProgress ? "Resume" : "Read",
                hasProgress ? "book.pages" : "book.fill", primary: true)
        case .bookVolume, .bookChapter:
            return action(
                hasProgress ? .resume : .read, hasProgress ? "Resume" : "Read",
                hasProgress ? "book.pages" : "book.fill", primary: true)
        default:
            return nil
        }
    }

    private func section(_ id: EntityDetailSectionID, _ title: String, _ image: String, count: Int? = nil)
        -> EntityDetailSection
    {
        .init(id: id, title: title, systemImage: image, count: count)
    }

    private func action(
        _ id: EntityDetailActionID, _ title: String, _ image: String, selected: Bool = false, primary: Bool = false
    ) -> EntityDetailAction {
        .init(id: id, title: title, systemImage: image, isSelected: selected, isPrimary: primary)
    }

    private static func titleCase(_ value: String) -> String {
        value.replacingOccurrences(of: "-", with: " ").split(separator: " ").map {
            $0.prefix(1).uppercased() + $0.dropFirst()
        }.joined(separator: " ")
    }

    private static func sourceOrder(_ lhs: EntityThumbnail, _ rhs: EntityThumbnail) -> Bool {
        if lhs.sortOrder != rhs.sortOrder {
            return (lhs.sortOrder ?? Int.max) < (rhs.sortOrder ?? Int.max)
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func yesNo(_ value: Bool) -> String {
        value ? "Yes" : "No"
    }

    private static func nonemptyPath(_ value: String?) -> String? {
        let path = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return path?.isEmpty == false ? path : nil
    }

    private static func duration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private static func resolutionLabel(width: Int, height: Int) -> String {
        if width >= 3_800 || height >= 2_100 { return "4K" }
        if width >= 1_900 || height >= 1_050 { return "1080p" }
        if height >= 700 { return "720p" }
        return "\(height)p"
    }

    private static func bitRate(_ bitsPerSecond: Int) -> String {
        if bitsPerSecond >= 1_000_000 {
            return "\((Double(bitsPerSecond) / 1_000_000).formatted(.number.precision(.fractionLength(0...1)))) Mbps"
        }
        return "\((Double(bitsPerSecond) / 1_000).formatted(.number.precision(.fractionLength(0...1)))) Kbps"
    }

    private static func channelLabel(_ channels: Int) -> String {
        switch channels {
        case 8: "7.1"
        case 6: "5.1"
        case 2: "Stereo"
        case 1: "Mono"
        default: "\(channels) channels"
        }
    }

    private static func externalURL(_ value: String) -> URL? {
        guard let url = URL(string: value),
            let scheme = url.scheme?.lowercased(),
            scheme == "http" || scheme == "https",
            url.host != nil
        else { return nil }
        return url
    }
}
