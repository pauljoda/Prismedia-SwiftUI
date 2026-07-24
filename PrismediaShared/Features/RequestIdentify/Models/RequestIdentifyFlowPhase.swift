import Foundation

#if os(iOS) || os(macOS)
    enum RequestIdentifyFlowPhase: Hashable, Sendable {
        case unavailable
        case unauthorized
        case initialDependencyLoading
        case searchReady
        case searching
        case results
        case empty
        case searchError
        case selection
        case reviewLoading
        case reviewReady
        case reviewError
        case committing
        case commitFailure
        case success
        case unknown(String)

        var locksDismissal: Bool {
            self == .committing
        }
    }
#endif
