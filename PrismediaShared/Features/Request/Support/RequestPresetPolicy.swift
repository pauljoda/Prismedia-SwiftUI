import Foundation

public enum RequestPresetPolicy {
    public static func selectedIDs(
        for preset: RequestMonitorPreset,
        children: [AdministrativeRequestReviewTarget]
    ) -> Set<String> {
        switch preset {
        case .all, .missing:
            Set(children.filter(\.requestable).map(\.proposalID))
        case .future, .manual, .custom:
            []
        }
    }

    public static func matchingPreset(
        selectedIDs: Set<String>,
        children: [AdministrativeRequestReviewTarget]
    ) -> RequestMonitorPreset {
        for preset in [RequestMonitorPreset.all, .missing, .future, .manual]
        where selectedIDs == self.selectedIDs(for: preset, children: children) {
            return preset
        }
        return .custom
    }
}
