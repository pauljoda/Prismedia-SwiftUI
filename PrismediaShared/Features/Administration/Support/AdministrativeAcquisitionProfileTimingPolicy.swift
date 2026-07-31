import Foundation

public enum AdministrativeAcquisitionProfileTimingPolicy {
    public static func supportedTypes(for kind: EntityKind) -> [EntityDateType] {
        let profileKind = RequestKindDefinition.allCases
            .first(where: { $0.acquisitionKind == kind })?
            .profileKind
            ?? kind.definition?.navigation?.canonicalBrowseKind
            ?? kind
        return profileKind.definition?.acquisitionProfile?.supportedReleaseDateTypes ?? [.release]
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
