import Foundation

enum VideoSidecarSubtitlePolicy {
    static func usesPreservedSource(
        sourceFormat: String?,
        supportsAssRenderer: Bool
    ) -> Bool {
        guard supportsAssRenderer else { return false }
        switch sourceFormat?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ass", "ssa": return true
        default: return false
        }
    }
}
