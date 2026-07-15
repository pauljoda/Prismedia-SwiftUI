import Foundation

struct EPUBProgressLocation: Equatable, Sendable {
    let href: String
    let resourceProgression: Double
    let totalProgression: Double?

    init?(serialized: String) {
        if let data = serialized.data(using: .utf8),
           let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let href = root["href"] as? String,
           !href.isEmpty,
           let locations = root["locations"] as? [String: Any] {
            self.href = href
            resourceProgression = Self.fraction(locations["progression"])
            totalProgression = locations["totalProgression"].flatMap(Self.optionalFraction)
            return
        }

        let marker = "#prismedia-progress="
        guard let range = serialized.range(of: marker),
              range.lowerBound != serialized.startIndex,
              let value = Double(serialized[range.upperBound...]),
              value.isFinite else { return nil }
        href = String(serialized[..<range.lowerBound])
        resourceProgression = min(max(0, value), 1)
        totalProgression = nil
    }

    private static func fraction(_ value: Any?) -> Double {
        guard let value else { return 0 }
        return optionalFraction(value) ?? 0
    }

    private static func optionalFraction(_ value: Any) -> Double? {
        let number: Double?
        if let value = value as? Double {
            number = value
        } else if let value = value as? NSNumber {
            number = value.doubleValue
        } else {
            number = nil
        }
        guard let number, number.isFinite else { return nil }
        return min(max(0, number), 1)
    }
}
