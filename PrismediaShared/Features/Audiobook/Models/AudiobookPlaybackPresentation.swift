import Foundation

public struct AudiobookPlaybackPresentation: Equatable, Sendable {
    public let actionTitle: String
    public let progress: MediaProgressCardPresentation

    public init(
        totalDuration: Double,
        partCount: Int,
        resumeSeconds: Double,
        isCompleted: Bool,
        isCurrentAudiobook: Bool,
        isPlaying: Bool,
        isBusy: Bool = false
    ) {
        let duration = max(0, totalDuration.isFinite ? totalDuration : 0)
        let resume = min(max(0, resumeSeconds.isFinite ? resumeSeconds : 0), duration)
        let status: MediaProgressStatus = isCompleted ? .completed : (resume > 0 ? .inProgress : .notStarted)
        let percent =
            isCompleted
            ? 100
            : (duration > 0 ? Int(((resume / duration) * 100).rounded()) : 0)

        if isCurrentAudiobook && isPlaying {
            actionTitle = "Pause"
        } else if isCompleted {
            actionTitle = "Listen Again"
        } else if resume > 0 {
            actionTitle = "Continue Listening"
        } else {
            actionTitle = "Listen"
        }

        progress = MediaProgressCardPresentation(
            kind: .listen,
            status: status,
            percent: percent,
            positionLabel: resume > 0 && duration > 0
                ? "\(MusicPresentation.clockTime(resume)) of \(MusicPresentation.clockTime(duration))"
                : nil,
            contextLabel: "\(partCount) \(partCount == 1 ? "part" : "parts")",
            showsResume: status == .inProgress && !(isCurrentAudiobook && isPlaying),
            showsStartOver: isCompleted || resume > 0,
            showsCompletionToggle: true,
            isBusy: isBusy
        )
    }
}
