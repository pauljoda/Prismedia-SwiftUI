import Foundation
import UniformTypeIdentifiers

struct RequestActivityManualFileSelectionService: Sendable {
    func load(_ urls: [URL]) async throws -> [RequestActivityManualUploadFile] {
        guard !urls.isEmpty else { throw RequestActivityManualSelectionError.noFiles }
        return try await Task.detached(priority: .userInitiated) {
            try urls.map(Self.load)
        }.value
    }

    private static func load(_ url: URL) throws -> RequestActivityManualUploadFile {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let values = try url.resourceValues(forKeys: [
                .isDirectoryKey, .isRegularFileKey, .fileSizeKey, .contentTypeKey,
            ])
            if values.isDirectory == true {
                throw RequestActivityManualSelectionError.folderUnsupported(url.lastPathComponent)
            }
            guard values.isRegularFile != false,
                let size = values.fileSize
            else {
                throw RequestActivityManualSelectionError.unreadable(url.lastPathComponent)
            }
            return RequestActivityManualUploadFile(
                url: url,
                fileName: url.lastPathComponent,
                sizeBytes: Int64(size),
                contentType: values.contentType?.preferredMIMEType ?? "application/octet-stream"
            )
        } catch let error as RequestActivityManualSelectionError {
            throw error
        } catch {
            throw RequestActivityManualSelectionError.unreadable(url.lastPathComponent)
        }
    }
}
