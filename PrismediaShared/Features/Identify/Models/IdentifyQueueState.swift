import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyQueueState: Hashable, Sendable {
        case queued
        case searching
        case choice
        case proposal
        case applying
        case done
        case deleted
        case error
        case unknown(String)

        init(rawServerValue: String) {
            switch rawServerValue.lowercased() {
            case "queued": self = .queued
            case "searching": self = .searching
            case "search": self = .choice
            case "proposal": self = .proposal
            case "applying": self = .applying
            case "done": self = .done
            case "deleted": self = .deleted
            case "error": self = .error
            default: self = .unknown(rawServerValue)
            }
        }

        var label: String {
            switch self {
            case .queued: "Queued"
            case .searching: "Searching"
            case .choice: "Choose"
            case .proposal: "Review"
            case .applying: "Applying"
            case .done: "Done"
            case .deleted: "Deleted"
            case .error: "Error"
            case .unknown(let value): value.replacingOccurrences(of: "-", with: " ").capitalized
            }
        }

        var isBusy: Bool { self == .queued || self == .searching || self == .applying }
        var isReviewable: Bool { self == .proposal || self == .choice || self == .error }
        var isTerminal: Bool { self == .done || self == .deleted || self == .error }
    }
#endif
