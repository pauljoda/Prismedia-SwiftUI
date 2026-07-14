import Foundation

struct ReaderChromeState: Equatable, Sendable {
    static let autoHideDelay = Duration.milliseconds(2_800)

    private(set) var isVisible = true
    private(set) var isPinned = false

    var shouldScheduleHide: Bool {
        isVisible && !isPinned
    }

    mutating func contentTapped() {
        guard !isPinned else {
            isVisible = true
            return
        }
        isVisible.toggle()
    }

    mutating func reveal() {
        isVisible = true
    }

    mutating func setPinned(_ pinned: Bool) {
        isPinned = pinned
        if pinned { isVisible = true }
    }

    mutating func hide() {
        guard !isPinned else { return }
        isVisible = false
    }
}
