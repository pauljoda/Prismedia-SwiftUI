import SwiftUI

enum EntityDetailSectionID: String, Hashable, Sendable {
    case details
    case metadata
    case chapterMapping = "chapter-mapping"
    case markers
    case transcript
    case acquisition
}
