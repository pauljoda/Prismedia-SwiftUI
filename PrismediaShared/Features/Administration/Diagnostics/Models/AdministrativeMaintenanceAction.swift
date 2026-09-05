import Foundation

/// Explicit maintenance choices, each requiring confirmation before queuing background work.
enum AdministrativeMaintenanceAction: CaseIterable, Hashable {
    case fingerprints
    case previews

    var title: String {
        switch self {
        case .fingerprints: "Generate Missing Fingerprints"
        case .previews: "Rebuild All Previews"
        }
    }
    var systemImage: String {
        switch self {
        case .fingerprints: "number"
        case .previews: "photo.badge.arrow.down"
        }
    }
    var confirmationTitle: String {
        switch self {
        case .fingerprints: "Generate missing fingerprints?"
        case .previews: "Rebuild all previews?"
        }
    }
    var explanation: String {
        switch self {
        case .fingerprints: "Queues background fingerprint generation. Source media is not deleted."
        case .previews: "Every video, image, book page, and audio track will be queued for preview regeneration. This can take a while. Source media is not deleted."
        }
    }
    var progressTitle: String {
        switch self {
        case .fingerprints: "Queuing fingerprint generation…"
        case .previews: "Queuing preview regeneration…"
        }
    }
}
