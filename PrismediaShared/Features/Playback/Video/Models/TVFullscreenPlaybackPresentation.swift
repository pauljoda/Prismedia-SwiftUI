import Foundation
import Observation

@Observable
@MainActor
final class TVFullscreenPlaybackPresentation: Identifiable {
    let id = UUID()
    private(set) var controller: VideoPlaybackController

    init(controller: VideoPlaybackController) {
        self.controller = controller
    }

    func updateController(_ controller: VideoPlaybackController) {
        self.controller = controller
    }
}
