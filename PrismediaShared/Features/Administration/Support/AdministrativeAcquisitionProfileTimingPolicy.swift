import Foundation

public enum AdministrativeAcquisitionProfileTimingPolicy {
    public static func supportedTypes(for kind: EntityKind) -> [EntityDateType] {
        switch kind {
        case .movie:
            [.premiere, .theatricalRelease, .streamingRelease, .digitalRelease, .physicalRelease, .release]
        case .video, .videoSeries, .videoSeason:
            [.premiere, .air, .firstAir, .streamingRelease, .digitalRelease, .release]
        case .book, .bookVolume:
            [.publication, .digitalRelease, .physicalRelease, .release]
        case .audio, .audioLibrary:
            [.release, .digitalRelease, .physicalRelease]
        default:
            [.release]
        }
    }

    public static func compatibilityDescription(for type: EntityDateType?) -> String? {
        guard let type, let fallback = type.compatibleFallback else { return nil }
        return "Uses \(type.displayName.lowercased()) first, then \(fallback.displayName.lowercased()) when the exact milestone is unavailable."
    }

    public static func summary(for profile: AdministrativeAcquisitionProfile) -> String {
        guard let type = profile.searchAfterDateType else { return "Immediately" }
        guard profile.searchDelayDays > 0 else { return "After \(type.displayName.lowercased())" }
        return "\(profile.searchDelayDays) day\(profile.searchDelayDays == 1 ? "" : "s") after \(type.displayName.lowercased())"
    }
}
