public enum ReleaseDatePromptPolicy {
    public static func offersManualEntry(metadataUnavailable: Bool) -> Bool {
        metadataUnavailable
    }
}
