import Foundation

extension AcquisitionStatus {
    var entityDetailDisplayName: String {
        if rawValue == "waiting-for-release" || rawValue == "manual-search-required" {
            return "Waiting for release"
        }
        return rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
