import Foundation

#if os(iOS) || os(macOS)
    /// How a release-candidate row presents its primary action.
    enum RequestActivityCandidateRowVariant: Equatable, Sendable {
        /// The request-activity sheet's original presentation: "Queue", enabled only for
        /// accepted releases.
        case queue
        /// Web-parity release review: "Download" (prominent) for accepted releases,
        /// "Download anyway" for rejected ones that remain manually queueable.
        case download
    }
#endif
