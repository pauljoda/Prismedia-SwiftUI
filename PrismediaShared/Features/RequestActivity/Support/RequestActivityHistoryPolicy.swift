import Foundation

public enum RequestActivityHistoryPolicy {
    public static func label(for event: RequestActivityHistoryEvent) -> String {
        switch event.rawValue {
        case "grabbed": "Grabbed"
        case "imported": "Imported"
        case "import-failed": "Import failed"
        case "download-failed": "Download failed"
        case "blocklisted": "Blocklisted"
        case "upgraded": "Upgraded"
        case "removed": "Removed"
        default: event.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    public static func systemImage(for event: RequestActivityHistoryEvent) -> String {
        switch event.rawValue {
        case "grabbed": "arrow.down.circle"
        case "imported": "checkmark.circle"
        case "import-failed": "exclamationmark.triangle"
        case "download-failed": "xmark.circle"
        case "blocklisted": "hand.raised"
        case "upgraded": "arrow.up.circle"
        case "removed": "trash"
        default: "questionmark.circle"
        }
    }

    public static func tone(for event: RequestActivityHistoryEvent) -> RequestActivityTone {
        switch event.rawValue {
        case "imported", "upgraded": .done
        case "import-failed", "download-failed", "removed": .failed
        case "blocklisted": .attention
        case "grabbed": .downloading
        default: .muted
        }
    }
}
