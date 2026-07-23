import Foundation

extension AcquisitionStatus {
    var entityDetailDisplayName: String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
