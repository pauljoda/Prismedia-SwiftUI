public struct EntityMediaFeedDependencies: Sendable {
    public let detailLoader: any EntityDetailLoading
    public let sourceLoader: (any EntityImageSourceLoading)?
    public let videoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)?

    public init(
        detailLoader: any EntityDetailLoading,
        sourceLoader: (any EntityImageSourceLoading)?,
        videoAspectRatioLoader: (any EntityImageVideoAspectRatioLoading)? = nil
    ) {
        self.detailLoader = detailLoader
        self.sourceLoader = sourceLoader
        self.videoAspectRatioLoader = videoAspectRatioLoader
    }
}
