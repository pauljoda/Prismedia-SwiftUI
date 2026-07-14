import Foundation

struct EntityImageViewerChromeState: Equatable, Sendable {
    static let autoHideDelay = Duration.milliseconds(2_800)

    private(set) var isVisible = true

    var shouldScheduleHide: Bool {
        isVisible
    }

    mutating func contentTapped() {
        isVisible.toggle()
    }

    mutating func pageChanged() {
        // Paging changes the selected media, not the viewer chrome. Preserve
        // the user's explicit visible or hidden state across the transition.
    }

    mutating func hide() {
        isVisible = false
    }
}
