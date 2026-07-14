enum VideoFullscreenOrientationPolicy {
    static func forcesLandscape(isPad: Bool) -> Bool {
        !isPad
    }
}
