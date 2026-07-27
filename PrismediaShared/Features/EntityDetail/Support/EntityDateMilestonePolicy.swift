import Foundation

public enum EntityDateMilestonePolicy {
    public static func sorted(_ dates: [EntityDate]) -> [EntityDate] {
        dates.sorted { lhs, rhs in
            let lhsOrder = lhs.type?.milestoneOrder ?? Int.max
            let rhsOrder = rhs.type?.milestoneOrder ?? Int.max
            if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
            if lhs.code != rhs.code { return lhs.code.localizedStandardCompare(rhs.code) == .orderedAscending }
            return lhs.value.localizedStandardCompare(rhs.value) == .orderedAscending
        }
    }

    public static func label(for date: EntityDate) -> String {
        date.type?.displayName ?? date.code.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
