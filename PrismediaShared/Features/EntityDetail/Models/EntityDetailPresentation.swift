import SwiftUI

struct EntityDetailPresentation {
    let detail: EntityDetail
    let canEditMetadata: Bool

    init(detail: EntityDetail, canEditMetadata: Bool = false) {
        self.detail = detail
        self.canEditMetadata = canEditMetadata
    }

    var sections: [EntityDetailSection] {
        var values = [section(.details, "Main", "square.text.square")]
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
            values.append(action(.identify, "Identify", "doc.viewfinder"))
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
            flags.isWanted == true
                ? .init(title: "Wanted", systemImage: "arrow.down.circle.fill", tone: .info) : nil,
        ].compactMap { $0 }
    }

    var markers: [EntityMarker] {
        detail.capability(EntityItemsCapability<EntityMarker>.self)?.items ?? []
    }

    var subtitles: [EntitySubtitle] {
        detail.capability(EntityItemsCapability<EntitySubtitle>.self)?.items ?? []
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
            case .dates(let dates):
                items += dates.items.prefix(3).map {
                    .init(label: Self.titleCase($0.code), value: $0.value, systemImage: "calendar")
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
                    items.append(.init(label: "Resolution", value: "\(width) × \(height)", systemImage: "rectangle"))
                }
                if let codec = technical.codec {
                    items.append(.init(label: "Codec", value: codec.uppercased(), systemImage: "film"))
                }
                if let format = technical.container ?? technical.format {
                    items.append(.init(label: "Format", value: format.uppercased(), systemImage: "doc"))
                }
            case .providerIdentity(let provider):
                items.append(.init(label: "Provider", value: provider.pluginID, systemImage: "network"))
                items.append(
                    .init(label: provider.identityNamespace, value: provider.identityValue, systemImage: "number"))
            case .source(let sources):
                items += sources.items.prefix(3).map {
                    .init(label: Self.titleCase($0.code), value: $0.value, systemImage: "externaldrive")
                }
            case .links(let links):
                items += links.externalIDs.prefix(3).map {
                    .init(label: $0.provider, value: $0.value, systemImage: "link")
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
        return Array(items.prefix(16))
    }

    func creditSubtitle(for personID: UUID) -> String? {
        guard let metadata = detail.creditMetadata.first(where: { $0.personID == personID }) else {
            return nil
        }
        return EntityDetailCreditSubtitlePolicy.subtitle(for: metadata)
    }

    private var supportsAcquisition: Bool {
        detail.hasSourceMedia || flagCapability?.isWanted != nil
    }

    private var hasMetadataCapability: Bool {
        detail.capabilities.contains {
            switch $0 {
            case .classification, .dates, .links, .providerIdentity, .source, .stats, .technical: return true
            default: return false
            }
        }
    }

    private var primaryAction: EntityDetailAction? {
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

    private static func nonemptyPath(_ value: String?) -> String? {
        let path = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return path?.isEmpty == false ? path : nil
    }

    private static func duration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
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
