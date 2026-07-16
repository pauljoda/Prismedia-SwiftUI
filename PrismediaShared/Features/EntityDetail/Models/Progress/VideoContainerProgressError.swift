import Foundation

enum VideoContainerProgressError: LocalizedError {
    case unavailable
    case missingFirstEpisode

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "Video progress can’t be updated right now."
        case .missingFirstEpisode:
            "The first episode couldn’t be found."
        }
    }
}
