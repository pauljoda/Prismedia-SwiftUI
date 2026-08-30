enum VideoInitialResumePosition {
    static func resolve(
        detailResumeSeconds: Double?,
        detailCompletedAt: String?,
        thumbnailResumeSeconds: Double?
    ) -> Double {
        guard detailCompletedAt == nil else { return 0 }
        return max(0, detailResumeSeconds ?? thumbnailResumeSeconds ?? 0)
    }
}
