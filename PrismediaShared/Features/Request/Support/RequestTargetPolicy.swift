import Foundation

public enum RequestTargetPolicy {
    public static func profiles(
        for kind: RequestKindDefinition,
        from profiles: [AdministrativeAcquisitionProfile]
    ) -> [AdministrativeAcquisitionProfile] {
        profiles.filter { $0.kind == kind.profileKind }
            .sorted { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending }
    }

    public static func roots(
        for kind: RequestKindDefinition,
        from roots: [RequestLibraryRoot],
        hidesNsfw: Bool
    ) -> [RequestLibraryRoot] {
        roots.filter { kind.supports(root: $0) && (!hidesNsfw || !$0.isNsfw) }
            .sorted {
                if $0.isNsfw != $1.isNsfw { return !$0.isNsfw }
                return $0.label.localizedStandardCompare($1.label) == .orderedAscending
            }
    }

    public static func defaultProfile(
        for kind: RequestKindDefinition,
        from profiles: [AdministrativeAcquisitionProfile]
    ) -> AdministrativeAcquisitionProfile? {
        let compatible = self.profiles(for: kind, from: profiles)
        return compatible.first(where: \.isDefault) ?? compatible.first
    }

    public static func defaultRootID(
        for profile: AdministrativeAcquisitionProfile?,
        compatibleRoots: [RequestLibraryRoot]
    ) -> UUID? {
        if let targetID = profile?.targetLibraryRootID,
            compatibleRoots.contains(where: { $0.id == targetID })
        {
            return targetID
        }
        return compatibleRoots.first?.id
    }
}
