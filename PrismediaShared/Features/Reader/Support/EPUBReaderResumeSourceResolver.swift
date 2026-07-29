import Foundation

struct EPUBReaderResumeSourceResolver: Sendable {
    func resolve(
        explicitLocation: String?,
        explicitProgression: Double?,
        deviceLocation: String?
    ) -> EPUBReaderResumeSource? {
        if let target = locationTarget(
            location: explicitLocation,
            progression: explicitProgression
        ) {
            return .explicit(target)
        }
        guard let deviceLocation,
            !deviceLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        return .device(deviceLocation)
    }

    func locationTarget(
        location: String?,
        progression: Double?
    ) -> BookReaderLocationTarget? {
        guard let location,
            !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }
        guard DocumentReaderProgressMapper.sharedEPUBLocation(location) == nil else {
            // Foliate CFIs are not safely convertible into Readium locators.
            return nil
        }
        if let parsed = EPUBProgressLocation(serialized: location) {
            return BookReaderLocationTarget(
                location: parsed.href,
                progression: progression ?? parsed.resourceProgression
            )
        }
        return BookReaderLocationTarget(
            location: DocumentReaderProgressMapper.epubBaseLocation(location) ?? location,
            progression: progression
                ?? DocumentReaderProgressMapper.epubProgress(from: location)
                ?? 0
        )
    }
}
