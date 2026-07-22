import Foundation

enum RequestActivityCandidateAction: Equatable, Sendable {
    case download(UUID)
    case blocklist(UUID)
}
