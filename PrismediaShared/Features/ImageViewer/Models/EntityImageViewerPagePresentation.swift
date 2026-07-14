public enum EntityImageViewerPagePresentation: Equatable {
    case media(EntityImageMediaProjection)
    case loading(fallbackPath: String?)
    case fallback(path: String)
    case failure(message: String)

    public static func resolve(
        projection: EntityImageMediaProjection?,
        isLoading: Bool,
        errorMessage: String?,
        fallbackArtworkPath: String?
    ) -> Self {
        if let projection {
            return .media(projection)
        }
        if isLoading {
            return .loading(fallbackPath: fallbackArtworkPath)
        }
        if let fallbackArtworkPath {
            return .fallback(path: fallbackArtworkPath)
        }
        if let errorMessage {
            return .failure(message: errorMessage)
        }
        return .loading(fallbackPath: nil)
    }
}
