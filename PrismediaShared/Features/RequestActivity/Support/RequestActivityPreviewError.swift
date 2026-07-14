import Foundation

#if DEBUG
    enum RequestActivityPreviewError: LocalizedError {
        case unavailable

        var errorDescription: String? {
            "The preview service is unavailable."
        }
    }
#endif
