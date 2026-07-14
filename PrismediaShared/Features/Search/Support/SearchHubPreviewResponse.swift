import SwiftUI

#if DEBUG
    enum SearchHubPreviewResponse: Sendable {
        case items([EntityThumbnail], totalCount: Int? = nil)
        case failure
        case loading
    }

#endif
