import Foundation

public enum RequestActivityHistoryPolicy {
    public static func label(for event: RequestActivityHistoryEvent) -> String {
        switch event.rawValue {
        case "grabbed": "Grabbed"
        case "imported": "Imported"
        case "import-failed": "Import Failed"
        case "download-failed": "Download Failed"
        case "blocklisted": "Blocklisted"
        case "upgraded": "Upgraded"
        case "removed": "Removed"
        default: event.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
        }
    }

    public static func systemImage(for event: RequestActivityHistoryEvent) -> String {
        switch event.rawValue {
        case "imported", "upgraded": "checkmark.circle"
        case "import-failed", "download-failed", "removed": "exclamationmark.circle"
        case "blocklisted": "hand.raised"
        default: "arrow.down.circle"
        }
    }

    public static func tone(for event: RequestActivityHistoryEvent) -> RequestActivityTone {
        switch event.rawValue {
        case "imported", "upgraded": .done
        case "import-failed", "download-failed", "removed": .failed
        case "blocklisted": .attention
        default: .downloading
        }
    }
}
