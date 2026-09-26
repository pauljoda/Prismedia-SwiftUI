import Foundation

/// A Prismedia server build version reported by `GET /api/health`. Features that depend on a
/// server contract are gated on the first release that ships them.
public struct PrismediaServerVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    // MARK: - Static Variables

    /// First release that owns Book reading/listening alignment and resume
    /// (`GET /api/books/{id}/alignment`) and records one progress checkpoint per modality.
    public static let bookAlignment = PrismediaServerVersion(major: 3, minor: 8, patch: 0)

    // MARK: - Variables

    public let major: Int
    public let minor: Int
    public let patch: Int

    public var description: String {
        "\(major).\(minor).\(patch)"
    }

    /// Whether the server owns Book alignment, resume, and modality checkpoints.
    public var servesBookAlignment: Bool {
        self >= .bookAlignment
    }

    // MARK: - Initializers

    public init(major: Int, minor: Int, patch: Int = 0) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// Parses a plain `X.Y.Z` (or `X.Y`) build version. Any prerelease or build suffix after the
    /// numeric components is ignored. Returns nil when the text does not start with a version.
    public init?(_ text: String?) {
        guard let text else { return nil }
        let numeric = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .prefix { $0.isNumber || $0 == "." }
        let components = numeric.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
        guard components.count >= 2,
            components.count <= 3,
            let major = components[0],
            let minor = components[1]
        else { return nil }
        let patch: Int
        if components.count == 3 {
            guard let value = components[2] else { return nil }
            patch = value
        } else {
            patch = 0
        }
        self.init(major: major, minor: minor, patch: patch)
    }

    // MARK: - Actions - Comparison

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.major, lhs.minor, lhs.patch) < (rhs.major, rhs.minor, rhs.patch)
    }
}
