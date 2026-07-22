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
        /// The server has accepted a request and is preparing the indexer search.
        case pending
        /// An interrupted import that can be resumed or discarded.
        case failedResumable
        /// A terminal attempt that remains available for another search.
        case cancelled
    }
#endif
