import Foundation

#if DEBUG
    enum RequestActivityPreviewScenario: Equatable, Sendable {
        case content
        case loading
        case empty
        case error
        /// A queued/downloading acquisition with a live transfer and partial files.
        case downloading
        /// An awaiting-selection acquisition with reviewable release candidates.
        case releases
    }
#endif
