import Foundation

#if DEBUG
    struct PreviewEntityAcquisitionFailure: LocalizedError {
        let message: String

        var errorDescription: String? { message }
    }
#endif
