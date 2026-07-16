import Foundation

enum VideoPlaybackRecoveryPolicy {
    static func shouldAttemptFallback(after error: Error?) -> Bool {
        guard var currentError = error as NSError? else { return true }
        while true {
            if currentError.domain == NSURLErrorDomain { return false }
            guard let underlyingError = currentError.userInfo[NSUnderlyingErrorKey] as? NSError else {
                return true
            }
            currentError = underlyingError
        }
    }
}
