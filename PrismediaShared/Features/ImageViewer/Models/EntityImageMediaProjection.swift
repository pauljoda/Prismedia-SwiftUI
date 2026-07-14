import Foundation

public struct EntityImageMediaProjection: Hashable, Sendable {
    public let entityID: UUID
    public let title: String
    public let mediaKind: EntityImageMediaKind
    public let sourceRole: String?
    public let sourcePath: String?
    public let playbackPath: String?
    public let fallbackArtworkPath: String?
    public let mimeType: String?

    public init(detail: EntityDetail) {
        let files =
            detail.capabilities.lazy.compactMap { capability -> [EntityFile]? in
                guard case .files(let value) = capability else { return nil }
                return value.items
            }.first ?? []
        let images = detail.capabilities.lazy.compactMap { capability -> EntityImagesCapability? in
            guard case .images(let value) = capability else { return nil }
            return value
        }.first
        let technical = detail.capabilities.lazy.compactMap { capability -> EntityTechnicalCapability? in
            guard case .technical(let value) = capability else { return nil }
            return value
        }.first
        let sourceFile = files.first { $0.role == "source" }
        let previewFile = files.first { $0.role == "preview" }
        let sourceMimeType = sourceFile?.mimeType?.lowercased()

        entityID = detail.id
        title = detail.title
        sourceRole = sourceFile?.role
        sourcePath = sourceFile.map { Self.fileEndpoint(entityID: detail.id, role: $0.role) }
        mimeType = sourceFile?.mimeType
        fallbackArtworkPath =
            images?.items.first(where: { $0.kind == "cover" })?.path
            ?? images?.items.first(where: { $0.kind == "poster" })?.path
            ?? images?.items.first(where: { $0.kind == "thumbnail" })?.path
            ?? images?.coverURL
            ?? images?.thumbnailURL

        let sourceExtension = Self.pathExtension(sourceFile?.path ?? detail.title)
        if Self.isAnimatedStill(mimeType: sourceMimeType, extension: sourceExtension) {
            mediaKind = .animatedImage
        } else if Self.isVideo(
            files: files,
            technical: technical,
            title: detail.title
        ) {
            mediaKind = .video
        } else {
            mediaKind = .stillImage
        }

        if mediaKind == .video {
            // Preserve native MP4/QuickTime sources so an explicitly unmuted
            // image loop can play its audio. Generated previews intentionally
            // omit audio, and remain the compatible fallback for WebM/other
            // source containers that AVPlayer cannot reliably decode.
            let playbackFile = sourceFile.flatMap(Self.nativePlaybackSource) ?? previewFile ?? sourceFile
            playbackPath = playbackFile.map {
                Self.playbackPath(for: $0, entityID: detail.id)
            }
        } else {
            playbackPath = nil
        }
    }

    private static func fileEndpoint(entityID: UUID, role: String) -> String {
        "/api/entities/\(entityID.uuidString.lowercased())/files/\(role)"
    }

    private static func playbackPath(for file: EntityFile, entityID: UUID) -> String {
        if file.role == "preview", file.path.hasPrefix("/assets/") {
            return file.path
        }
        return fileEndpoint(entityID: entityID, role: file.role)
    }

    private static func nativePlaybackSource(_ file: EntityFile) -> EntityFile? {
        let mimeType = file.mimeType?.lowercased()
        let fileExtension = pathExtension(file.path)
        guard
            mimeType == "video/mp4"
                || mimeType == "video/quicktime"
                || ["m4v", "mov", "mp4"].contains(fileExtension)
        else { return nil }
        return file
    }

    private static func isAnimatedStill(mimeType: String?, extension: String) -> Bool {
        mimeType == "image/gif"
            || mimeType == "image/apng"
            || ["gif", "apng"].contains(`extension`)
    }

    private static func isVideo(
        files: [EntityFile],
        technical: EntityTechnicalCapability?,
        title: String
    ) -> Bool {
        if files.contains(where: { $0.mimeType?.lowercased().hasPrefix("video/") == true }) {
            return true
        }
        if files.contains(where: { videoExtensions.contains(pathExtension($0.path)) }) {
            return true
        }
        if let container = technical?.container?.lowercased(), videoContainers.contains(container) {
            return true
        }
        if let format = technical?.format?.lowercased(), videoContainers.contains(format) {
            return true
        }
        return videoExtensions.contains(pathExtension(title))
    }

    private static func pathExtension(_ path: String) -> String {
        let cleaned = path.split(separator: "?", maxSplits: 1)[0]
            .split(separator: "#", maxSplits: 1)[0]
        guard let value = cleaned.split(separator: ".").last,
            cleaned.contains(".")
        else { return "" }
        return value.lowercased()
    }

    private static let videoExtensions: Set<String> = [
        "avi", "flv", "m4v", "mkv", "mov", "mp4", "ogg", "ogv", "webm", "wmv",
    ]

    private static let videoContainers: Set<String> = [
        "avi", "flv", "matroska", "mkv", "mov", "mp4", "mpeg4", "ogg", "quicktime", "webm", "wmv",
    ]
}
