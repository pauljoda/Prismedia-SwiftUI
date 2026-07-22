import Foundation

enum RequestActivityFilesPresentationPolicy {
    static func progress(for files: RequestActivityFiles) -> RequestActivityFileCountProgress {
        let processed = files.files.count { file in
            switch file.status?.value {
            case .imported, .skipped, .failed: true
            default: false
            }
        }
        return RequestActivityFileCountProgress(processed: processed, total: files.files.count)
    }

    static func isExpandedByDefault(_ files: RequestActivityFiles) -> Bool {
        if files.phase?.value != .imported { return true }
        return files.files.contains { file in
            file.status?.value == .skipped || file.status?.value == .failed
        }
    }

    static func statusLabel(for file: RequestActivityFile) -> String {
        switch file.status?.value {
        case .downloaded: "Downloaded"
        case .pendingImport: "Pending"
        case .importing: "Importing"
        case .imported: "Imported"
        case .skipped: "Skipped"
        case .failed: "Failed"
        case nil: file.progress >= 1 ? "Ready" : "Downloading"
        }
    }

    static func decisionLabel(for decision: RequestActivityFileDecision) -> String {
        switch decision.value {
        case .placeNew: "Placed as a new library file"
        case .replaceUpgrade: "Replaced an older library file"
        case .adoptExisting: "Adopted an identical existing file"
        case .skipExisting: "Skipped because the file already exists"
        case .skipNotUpgrade: "Skipped because the library copy is equal or better"
        case .holdFormatChange: "Held because the upgrade changes format"
        case .holdStructuralConflict: "Held because the file mapping is ambiguous"
        case .unsupported: "Unsupported file"
        case .ambiguous: "Could not determine a safe destination"
        case nil: decision.rawValue
        }
    }
}
