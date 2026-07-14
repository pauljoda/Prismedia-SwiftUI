public struct VideoPlaybackStreamChoice: Equatable, Sendable {
    public let index: Int
    public let title: String
    public let isSelected: Bool

    public init(index: Int, title: String, isSelected: Bool = false) {
        self.index = index
        self.title = title
        self.isSelected = isSelected
    }
}
