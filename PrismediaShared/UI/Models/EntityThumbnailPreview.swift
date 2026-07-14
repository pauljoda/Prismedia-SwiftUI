import Foundation

public struct EntityThumbnailPreview: Hashable, Sendable {
    public let kind: EntityThumbnailHoverKind
    public let restingArtworkPath: String?
    public let spritePlaylistPath: String?
    public let imageOptions: [EntityThumbnailPreviewOption]

    public init(thumbnail: EntityThumbnail) {
        restingArtworkPath = thumbnail.bestCoverPath ?? thumbnail.hoverImages.first?.path

        if thumbnail.hoverKind.supportsSpritePreview,
            let hoverURL = thumbnail.hoverURL,
            !hoverURL.isEmpty
        {
            kind = .sprite
            spritePlaylistPath = hoverURL
            imageOptions = []
            return
        }

        let options = thumbnail.hoverImages.map {
            EntityThumbnailPreviewOption(
                entityID: $0.entityID,
                title: $0.title,
                path: $0.path
            )
        }
        if !options.isEmpty {
            kind = .imageSequence
            spritePlaylistPath = nil
            imageOptions = options
            return
        }

        kind = .none
        spritePlaylistPath = nil
        imageOptions = []
    }

    public var hasInteractivePreview: Bool {
        spritePlaylistPath != nil || !imageOptions.isEmpty
    }

    public static func ratio(location: Double, width: Double) -> Double {
        guard location.isFinite, width.isFinite, width > 0 else { return 0 }
        return min(1, max(0, location / width))
    }

    public static func index(for ratio: Double, count: Int) -> Int? {
        guard count > 0 else { return nil }
        guard ratio.isFinite else { return 0 }
        let clampedRatio = min(1, max(0, ratio))
        return min(count - 1, Int(floor(clampedRatio * Double(count))))
    }

    public func accessibilityValue(at index: Int?) -> String {
        guard let index, !imageOptions.isEmpty else { return "Cover" }
        let clampedIndex = min(imageOptions.count - 1, max(0, index))
        let option = imageOptions[clampedIndex]
        return "Preview \(clampedIndex + 1) of \(imageOptions.count), \(option.title)"
    }
}

extension EntityThumbnailHoverKind {
    fileprivate var supportsSpritePreview: Bool {
        switch self {
        case .sprite, .trickplay: true
        case .none, .imageSequence, .unknown: false
        }
    }
}
