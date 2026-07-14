enum VideoInitialResumePosition {
    static func resolve(detailResumeSeconds: Double?, thumbnailResumeSeconds: Double?) -> Double {
        max(0, detailResumeSeconds ?? thumbnailResumeSeconds ?? 0)
    }
}
