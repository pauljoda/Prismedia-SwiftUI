public enum VideoPlaybackLaunchPolicy {
    public static func shouldPrepareAutomatically(
        for intent: EntityNavigationIntent
    ) -> Bool {
        intent == .playback
    }

    public static func shouldAutoPlayOnTV(
        isValidationPlaybackPaused: Bool
    ) -> Bool {
        !isValidationPlaybackPaused
    }

    public static func shouldOfferResumeChoice(
        resumeSeconds: Double?
    ) -> Bool {
        guard let resumeSeconds else { return false }
        return resumeSeconds.isFinite && resumeSeconds > 0
    }

    public static func shouldAutoStartFullscreen(
        resumeSeconds: Double?
    ) -> Bool {
        !shouldOfferResumeChoice(resumeSeconds: resumeSeconds)
    }

    public static func presentationMode(
        for ownerLink: EntityLink
    ) -> VideoPlaybackPresentationMode {
        guard ownerLink.intent == .playback,
            ownerLink.kind == .videoSeason,
            ownerLink.sourceThumbnail?.kind == .video
        else { return .inline }
        return .fullscreenOnly
    }
}
