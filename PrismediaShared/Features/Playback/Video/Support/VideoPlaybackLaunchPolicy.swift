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
