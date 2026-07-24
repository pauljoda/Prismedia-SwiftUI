import Foundation

#if os(iOS) || os(macOS)
    enum RequestIdentifyFlowRoute: Hashable, Sendable {
        case identifyReview
    }
#endif
