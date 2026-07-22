import Foundation

enum RequestActivityManualUploadPolicy {
    static let contentUploadLimitBytes: Int64 = 250 * 1_024 * 1_024 * 1_024

    static func supportsContentUpload(for kind: EntityKind) -> Bool {
        [.book, .movie, .video, .audioLibrary, .videoSeason].contains(kind)
    }

    static func canUploadContent(
        kind: EntityKind,
        hasOwnedContent: Bool,
        acquisitionStatus: AcquisitionStatus?
    ) -> Bool {
        guard supportsContentUpload(for: kind) else { return false }
        if let acquisitionStatus {
            if activeUploadReadyStatuses.contains(acquisitionStatus.rawValue) {
                return true
            }
            if acquisitionStatus.rawValue != "imported" {
                return false
            }
        }
        return hasOwnedContent && replaceableKinds.contains(kind)
    }

    static func validateContent(
        _ files: [RequestActivityManualUploadFile],
        kind: EntityKind,
        bookRendition: RequestActivityBookRendition?
    ) throws {
        guard !files.isEmpty else { throw RequestActivityManualSelectionError.noFiles }
        try validateCommon(files)
        guard files.contains(where: {
            supportedPrimaryExtensions(kind: kind, bookRendition: bookRendition)
                .contains($0.url.pathExtension.lowercased())
        }) else {
            throw RequestActivityManualSelectionError.unsupportedPrimary(kind)
        }
    }

    static func validateTorrent(_ file: RequestActivityManualUploadFile?) throws {
        guard let file,
            file.sizeBytes > 0,
            file.url.pathExtension.caseInsensitiveCompare("torrent") == .orderedSame
        else {
            throw RequestActivityManualSelectionError.torrentRequired
        }
    }

    static func summary(for files: [RequestActivityManualUploadFile]) -> String {
        let size = ByteCountFormatter.string(
            fromByteCount: files.reduce(0) { $0 + $1.sizeBytes },
            countStyle: .file
        )
        return files.count == 1 ? size : "\(files.count) files · \(size)"
    }

    private static func validateCommon(_ files: [RequestActivityManualUploadFile]) throws {
        var names = Set<String>()
        var totalBytes: Int64 = 0
        for file in files {
            guard file.sizeBytes > 0 else {
                throw RequestActivityManualSelectionError.empty(file.fileName)
            }
            let name = file.relativePath.lowercased()
            guard names.insert(name).inserted else {
                throw RequestActivityManualSelectionError.duplicate(file.fileName)
            }
            let (nextTotal, overflow) = totalBytes.addingReportingOverflow(file.sizeBytes)
            guard !overflow, nextTotal <= contentUploadLimitBytes else {
                throw RequestActivityManualSelectionError.overLimit
            }
            totalBytes = nextTotal
        }
    }

    private static func supportedPrimaryExtensions(
        kind: EntityKind,
        bookRendition: RequestActivityBookRendition?
    ) -> Set<String> {
        switch kind {
        case .book:
            if bookRendition?.rawValue == "audiobook" { return audiobookExtensions }
            return bookExtensions.union(audiobookExtensions)
        case .movie, .video, .videoSeason:
            return videoExtensions
        case .audioLibrary:
            return audioExtensions
        default:
            return []
        }
    }

    private static let activeUploadReadyStatuses: Set<String> = [
        "pending", "searching", "awaiting-selection", "failed",
        "manual-import-required", "cancelled",
    ]
    private static let replaceableKinds: Set<EntityKind> = [.book, .movie, .video, .audioLibrary]
    private static let bookExtensions: Set<String> = ["epub", "pdf", "cbz", "zip"]
    private static let audiobookExtensions: Set<String> = ["m4b", "m4a", "mp3"]
    private static let videoExtensions: Set<String> = [
        "mp4", "m4v", "mkv", "mov", "webm", "avi", "wmv", "flv", "ts", "m2ts", "mpg", "mpeg",
    ]
    private static let audioExtensions: Set<String> = [
        "mp3", "flac", "wav", "ogg", "aac", "m4a", "m4b", "wma", "opus",
        "aiff", "aif", "alac", "ape", "dsf", "dff", "wv",
    ]
}
