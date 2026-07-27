import Foundation

/// Canonical semantic date keys from the Prismedia OpenAPI contract.
public enum EntityDateType: String, Codable, CaseIterable, Hashable, Sendable {
    case announcement
    case premiere
    case theatricalRelease = "theatrical-release"
    case streamingRelease = "streaming-release"
    case digitalRelease = "digital-release"
    case physicalRelease = "physical-release"
    case air
    case firstAir = "first-air"
    case lastAir = "last-air"
    case publication
    case release
    case birth
    case death
    case careerStart = "career-start"
    case careerEnd = "career-end"

    /// Resolves canonical API codes and the legacy provider aliases accepted by the server.
    public init?(metadataCode: String) {
        let code = metadataCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if let canonical = Self(rawValue: code) {
            self = canonical
            return
        }

        switch code {
        case "released", "date": self = .release
        case "aired", "airDate": self = .air
        case "firstAir": self = .firstAir
        case "lastAir": self = .lastAir
        case "published": self = .publication
        case "theatrical": self = .theatricalRelease
        case "streaming": self = .streamingRelease
        case "digital": self = .digitalRelease
        case "physical": self = .physicalRelease
        default: return nil
        }
    }

    public var displayName: String {
        switch self {
        case .announcement: "Announcement"
        case .premiere: "Premiere"
        case .theatricalRelease: "Theatrical release"
        case .streamingRelease: "Streaming release"
        case .digitalRelease: "Digital / VOD release"
        case .physicalRelease: "Physical release"
        case .air: "Air date"
        case .firstAir: "First air date"
        case .lastAir: "Last air date"
        case .publication: "Publication"
        case .release: "General release"
        case .birth: "Birth"
        case .death: "Death"
        case .careerStart: "Career start"
        case .careerEnd: "Career end"
        }
    }

    public var milestoneOrder: Int {
        switch self {
        case .announcement: 0
        case .premiere: 1
        case .theatricalRelease: 2
        case .firstAir: 3
        case .air: 4
        case .streamingRelease: 5
        case .digitalRelease: 6
        case .physicalRelease: 7
        case .publication: 8
        case .release: 9
        case .lastAir: 10
        case .birth: 11
        case .careerStart: 12
        case .careerEnd: 13
        case .death: 14
        }
    }

    public var compatibleFallback: EntityDateType? {
        switch self {
        case .streamingRelease: .digitalRelease
        case .digitalRelease: .streamingRelease
        default: nil
        }
    }
}
