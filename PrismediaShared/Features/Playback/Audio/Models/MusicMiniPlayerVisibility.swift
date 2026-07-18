import Foundation
import Observation

@Observable
@MainActor
final class MusicMiniPlayerVisibility {
    private var suppressingSurfaceIDs: Set<UUID> = []
    private var isHiddenByUser = false

    var isSuppressed: Bool {
        isHiddenByUser || !suppressingSurfaceIDs.isEmpty
    }

    func suppress(id: UUID) {
        suppressingSurfaceIDs.insert(id)
    }

    func restore(id: UUID) {
        suppressingSurfaceIDs.remove(id)
    }

    func hideByUser() {
        isHiddenByUser = true
    }

    func revealForPlaybackActivity() {
        isHiddenByUser = false
    }
}
