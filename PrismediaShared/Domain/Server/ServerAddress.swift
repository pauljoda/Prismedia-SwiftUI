import Foundation

/// A validated, normalized Prismedia server base URL.
///
/// Accepts bare hosts ("media.example.com", "192.168.1.20:8008") and infers the
/// scheme: plain-http for localhost, .local, and private-LAN IPv4 hosts, https
/// for everything else.
public struct ServerAddress: Codable, Equatable, Sendable {
    public let url: URL

    public init(url: URL) throws {
        guard let normalized = Self.normalized(url) else {
            throw ServerAddressError.invalidURL
        }
        self.url = normalized
    }

    public init(text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ServerAddressError.invalidURL
        }

        let candidate =
            trimmed.contains("://")
            ? trimmed
            : "\(Self.defaultScheme(for: trimmed))://\(trimmed)"

        guard let url = URL(string: candidate) else {
            throw ServerAddressError.invalidURL
        }

        try self.init(url: url)
    }

    private static func normalized(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        guard let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return nil
        }

        guard components.host?.isEmpty == false else {
            return nil
        }

        components.scheme = scheme
        components.query = nil
        components.fragment = nil

        if components.path == "/" {
            components.path = ""
        }

        return components.url
    }

    private static func defaultScheme(for text: String) -> String {
        guard
            let components = URLComponents(string: "http://\(text)"),
            let host = components.host?.lowercased()
        else {
            return "https"
        }

        if host == "localhost" || host.hasSuffix(".localhost") || host.hasSuffix(".local") {
            return "http"
        }

        if isPrivateIPv4Address(host) {
            return "http"
        }

        return "https"
    }

    private static func isPrivateIPv4Address(_ host: String) -> Bool {
        let octets = host.split(separator: ".").compactMap { Int($0) }
        guard octets.count == 4, octets.allSatisfy({ 0...255 ~= $0 }) else {
            return false
        }

        return octets[0] == 10 || octets[0] == 127 || (octets[0] == 172 && 16...31 ~= octets[1])
            || (octets[0] == 192 && octets[1] == 168) || (octets[0] == 169 && octets[1] == 254)
    }
}
