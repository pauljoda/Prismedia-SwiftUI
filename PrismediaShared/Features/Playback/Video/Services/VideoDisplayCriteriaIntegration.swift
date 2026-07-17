@MainActor
struct VideoDisplayCriteriaIntegration {
    static let inactive = Self(prepare: { _ in }, reset: {})

    private let prepareCriteria: (VideoPlaybackDisplayMetadata?) async -> Void
    private let resetCriteria: () -> Void

    init(
        prepare: @escaping (VideoPlaybackDisplayMetadata?) async -> Void,
        reset: @escaping () -> Void
    ) {
        prepareCriteria = prepare
        resetCriteria = reset
    }

    func prepare(_ metadata: VideoPlaybackDisplayMetadata?) async {
        await prepareCriteria(metadata)
    }

    func reset() {
        resetCriteria()
    }
}
