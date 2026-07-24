import Foundation

#if os(iOS) || os(macOS)
    enum IdentifySearchRetryOperation: Hashable, Sendable {
        case search(fields: [String: String], limit: Int)
        case rescan
        case seek
        case resolve(AdministrativeEntitySearchCandidate)
    }
#endif
