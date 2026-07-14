public struct MediaProgressCardActions {
    public let resume: () -> Void
    public let startOver: () -> Void
    public let toggleCompletion: () -> Void

    public init(
        resume: @escaping () -> Void,
        startOver: @escaping () -> Void,
        toggleCompletion: @escaping () -> Void
    ) {
        self.resume = resume
        self.startOver = startOver
        self.toggleCompletion = toggleCompletion
    }
}
