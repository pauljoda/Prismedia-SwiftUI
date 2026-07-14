import Foundation

public struct TVPlaybackOptions: Equatable, Sendable {
    public let resumeSeconds: Double

    public init(resumeSeconds: Double) {
        self.resumeSeconds = max(0, resumeSeconds)
    }

    public var actions: [TVPlaybackAction] {
        guard resumeSeconds > 1 else { return [.play] }
        return [.resume(seconds: resumeSeconds), .playFromBeginning]
    }

    /// Action used when an episode is activated from a television rail.
    /// Manual presentation still exposes every action in `actions`.
    public var automaticAction: TVPlaybackAction {
        resumeSeconds > 1 ? .resume(seconds: resumeSeconds) : .play
    }
}
