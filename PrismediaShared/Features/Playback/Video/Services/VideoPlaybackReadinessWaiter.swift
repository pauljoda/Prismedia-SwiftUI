@preconcurrency import AVFoundation
import Foundation

@MainActor
struct VideoPlaybackReadinessWaiter {
    private enum ReadinessError: LocalizedError {
        case failed(String)
        var errorDescription: String? { if case .failed(let message) = self { message } else { nil } }
    }
    private let waitForReadiness: @MainActor (VideoPlaybackController) async throws -> Void
    init(_ waitForReadiness: @escaping @MainActor (VideoPlaybackController) async throws -> Void) {
        self.waitForReadiness = waitForReadiness
    }
    func callAsFunction(_ controller: VideoPlaybackController) async throws { try await waitForReadiness(controller) }
    static let live = Self(liveWaitForReadiness)
    private static func liveWaitForReadiness(_ controller: VideoPlaybackController) async throws {
        while true {
            try Task.checkCancellation()
            if let message = controller.errorMessage { throw ReadinessError.failed(message) }
            if controller.isReadyToPlay { return }
            if !controller.isLoading, controller.player.currentItem == nil { throw CancellationError() }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }
}
