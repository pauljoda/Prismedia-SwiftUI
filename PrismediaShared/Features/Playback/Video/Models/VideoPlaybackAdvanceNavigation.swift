import Foundation

struct VideoPlaybackAdvanceNavigation {
    private var advancedWhileFullscreen = false

    mutating func receive(_ link: EntityLink, isFullscreen: Bool) -> EntityLink? {
        guard isFullscreen else {
            advancedWhileFullscreen = false
            return link
        }
        advancedWhileFullscreen = true
        return nil
    }

    mutating func fullscreenDidDismiss() -> Bool {
        defer { advancedWhileFullscreen = false }
        return advancedWhileFullscreen
    }
}
