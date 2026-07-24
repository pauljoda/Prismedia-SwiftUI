import Foundation

#if os(iOS) || os(macOS)
    enum IdentifyChildReviewState: Hashable, Sendable {
        case matched
        case loading
        case queued
        case noMatch
    }
#endif
