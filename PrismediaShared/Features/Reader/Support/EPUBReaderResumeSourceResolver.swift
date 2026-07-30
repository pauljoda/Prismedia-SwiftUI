import Foundation

struct EPUBReaderResumeSourceResolver: Sendable {
    func resolve(
        explicitLocation: String?,
        explicitProgression: Double?,
        deviceLocation: String?
    ) -> EPUBReaderResumeSource? {
        if let explicitLocation,
            let parsed = EPUBProgressLocation(serialized: explicitLocation),
            parsed.isSerializedLocator
        {
            if let deviceLocation,
                let device = EPUBProgressLocation(serialized: deviceLocation),
                device.isSerializedLocator,
                isFarther(device, than: parsed)
            {
                return .device(deviceLocation)
            }
            return .explicitLocator(explicitLocation)
        }
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

    private func isFarther(
        _ candidate: EPUBProgressLocation,
        than current: EPUBProgressLocation
    ) -> Bool {
        if let candidateTotal = candidate.totalProgression,
            let currentTotal = current.totalProgression
        {
            return candidateTotal > currentTotal
        }
        guard EPUBResourceLocationMatcher().bestMatch(
            for: candidate.href,
            candidates: [current.href]
        ) != nil else { return false }
        return candidate.resourceProgression > current.resourceProgression
    }
}
