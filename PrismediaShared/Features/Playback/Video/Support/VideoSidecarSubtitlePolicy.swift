import Foundation

enum VideoSidecarSubtitlePolicy {
    static func usesPreservedSource(
        sourceFormat: String?,
        sourcePath: String?,
        supportsAssRenderer: Bool
    ) -> Bool {
        guard supportsAssRenderer,
            sourcePath?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        else { return false }
        switch sourceFormat?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "ass", "ssa": return true
        default: return false
        }
    }
}
