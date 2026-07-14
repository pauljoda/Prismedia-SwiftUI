import Foundation

#if os(iOS) || os(macOS)
    public enum ManageDestination: String, Codable, Hashable, Sendable {
        case files
        case identify
        case request
    }
#endif
