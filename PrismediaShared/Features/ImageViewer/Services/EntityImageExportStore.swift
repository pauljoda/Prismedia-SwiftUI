import Foundation

public actor EntityImageExportStore {
    private let rootDirectory: URL
    private let fileManager: FileManager?
    private var artifactURLs = Set<URL>()

    public init(
        rootDirectory: URL = FileManager.default.temporaryDirectory.appending(
            path: "Prismedia-Image-Exports-\(UUID().uuidString)",
            directoryHint: .isDirectory
        ),
        fileManager: FileManager = .default
    ) {
        precondition(rootDirectory.isFileURL, "Image export storage must use a local directory.")
        self.rootDirectory = rootDirectory.standardizedFileURL
        self.fileManager = fileManager
    }

    #if DEBUG
        init(previewDisabled: Bool) {
            precondition(previewDisabled)
            rootDirectory = URL(fileURLWithPath: "/preview-image-exports", isDirectory: true)
            fileManager = nil
        }
    #endif

    public func createArtifact(
        data: Data,
        title: String,
        mimeType: String?
    ) throws -> EntityImageExportArtifact {
        guard let fileManager else { throw CancellationError() }
        try fileManager.createDirectory(
            at: rootDirectory,
            withIntermediateDirectories: true
        )
        let fileURL = uniqueFileURL(
            baseName: safeBaseName(from: title),
            pathExtension: preferredPathExtension(title: title, mimeType: mimeType)
        )
        try data.write(to: fileURL, options: .atomic)
        artifactURLs.insert(fileURL)
        return EntityImageExportArtifact(fileURL: fileURL, mimeType: mimeType)
    }

    public func removeArtifact(_ artifact: EntityImageExportArtifact) {
        guard let fileManager else { return }
        let fileURL = artifact.fileURL.standardizedFileURL
        guard artifactURLs.remove(fileURL) != nil else { return }
        try? fileManager.removeItem(at: fileURL)
        removeRootIfEmpty()
    }

    public func removeAll() {
        guard let fileManager else { return }
        artifactURLs.removeAll()
        try? fileManager.removeItem(at: rootDirectory)
    }

    private func uniqueFileURL(baseName: String, pathExtension: String) -> URL {
        guard let fileManager else {
            return fileURL(baseName: baseName, suffix: nil, pathExtension: pathExtension)
        }
        var suffix = 1
        var candidate = fileURL(
            baseName: baseName,
            suffix: nil,
            pathExtension: pathExtension
        )
        while fileManager.fileExists(atPath: candidate.path) {
            suffix += 1
            candidate = fileURL(
                baseName: baseName,
                suffix: suffix,
                pathExtension: pathExtension
            )
        }
        return candidate
    }

    private func fileURL(
        baseName: String,
        suffix: Int?,
        pathExtension: String
    ) -> URL {
        let suffixText = suffix.map { "-\($0)" } ?? ""
        return rootDirectory.appending(
            path: "\(baseName)\(suffixText).\(pathExtension)",
            directoryHint: .notDirectory
        )
    }

    private func safeBaseName(from title: String) -> String {
        let lastComponent = URL(fileURLWithPath: title).lastPathComponent
        let stem = URL(fileURLWithPath: lastComponent).deletingPathExtension().lastPathComponent
        let allowed = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: "-_()"))
        let filteredScalars = stem.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let filtered = String(filteredScalars)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".-"))
        let collapsed = filtered.replacingOccurrences(
            of: #"[-\s]{2,}"#,
            with: "-",
            options: .regularExpression
        )
        return String((collapsed.isEmpty ? "Prismedia-Image" : collapsed).prefix(96))
    }

    private func preferredPathExtension(title: String, mimeType: String?) -> String {
        if let mimeType,
            let mapped = Self.mimeTypeExtensions[mimeType.lowercased()]
        {
            return mapped
        }
        let candidate = URL(fileURLWithPath: title).pathExtension.lowercased()
        let safeCandidate = candidate.filter { $0.isASCII && ($0.isLetter || $0.isNumber) }
        return safeCandidate.isEmpty ? "bin" : String(safeCandidate.prefix(12))
    }

    private func removeRootIfEmpty() {
        guard let fileManager else { return }
        guard artifactURLs.isEmpty else { return }
        try? fileManager.removeItem(at: rootDirectory)
    }

    private static let mimeTypeExtensions = [
        "image/avif": "avif",
        "image/gif": "gif",
        "image/heic": "heic",
        "image/heif": "heif",
        "image/jpeg": "jpg",
        "image/png": "png",
        "image/tiff": "tiff",
        "image/webp": "webp",
        "video/mp4": "mp4",
        "video/quicktime": "mov",
        "video/webm": "webm",
    ]
}
