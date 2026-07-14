public struct EntityImageAutoplayPolicy: Sendable {
    public static func shouldPlay(
        isVisible: Bool,
        isPausedByUser: Bool,
        reduceMotion: Bool,
        isSceneActive: Bool,
        isExplicitPlaybackRequested: Bool = false
    ) -> Bool {
        isVisible
            && !isPausedByUser
            && isSceneActive
            && (!reduceMotion || isExplicitPlaybackRequested)
    }
}
