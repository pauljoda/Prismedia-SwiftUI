struct VideoCompatibilityAudioSelectionState {
    private var pendingInitialStreamIndex: Int?

    mutating func prepare(initialStreamIndex: Int?) {
        pendingInitialStreamIndex = initialStreamIndex
    }

    mutating func takeInitialStreamIndex() -> Int? {
        defer { pendingInitialStreamIndex = nil }
        return pendingInitialStreamIndex
    }

    mutating func explicitSelectionWasRequested() {
        pendingInitialStreamIndex = nil
    }
}
