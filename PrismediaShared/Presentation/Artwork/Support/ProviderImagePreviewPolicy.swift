import Foundation

/// Right-sizes provider artwork URLs for on-screen previews, matching the
/// Prismedia Web policy. Providers hand back full-resolution artwork (TMDB
/// `original` posters are 2000×3000; googleusercontent covers ~1000px), and
/// loading dozens of those for candidate lists and artwork grids stalls or
/// drops image loads. The original URL is untouched for anything applied or
/// committed — only the preview shrinks.
public enum ProviderImagePreviewPolicy {
    /// Returns a preview-sized URL for known provider image hosts, or the
    /// original URL string unchanged.
    public static func previewURL(
        for url: String?,
        imageKind: String = "poster",
        targetKind: String? = nil
    ) -> String? {
        guard let url, !url.isEmpty else { return url }
        return tmdbPreviewURL(url, imageKind: imageKind, targetKind: targetKind)
            ?? googlePreviewURL(url, imageKind: imageKind)
            ?? url
    }

    /// Rewrites `image.tmdb.org/t/p/{size}/…` to a preview size for the image kind.
    private static func tmdbPreviewURL(
        _ urlString: String,
        imageKind: String,
        targetKind: String?
    ) -> String? {
        guard var components = URLComponents(string: urlString),
            components.host == "image.tmdb.org"
        else { return nil }
        var parts = components.path.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard let pIndex = parts.dropFirst().indices.first(where: { index in
            parts[index] == "p" && index > 0 && parts[index - 1] == "t"
        }), parts.indices.contains(pIndex + 1), !parts[pIndex + 1].isEmpty
        else { return nil }
        parts[pIndex + 1] = tmdbPreviewSize(imageKind: imageKind, targetKind: targetKind)
        components.path = parts.joined(separator: "/")
        return components.string
    }

    private static func tmdbPreviewSize(imageKind: String, targetKind: String?) -> String {
        let normalized = imageKind.lowercased()
        if targetKind?.lowercased() == "person", normalized != "backdrop", normalized != "logo" {
            return "w185"
        }
        switch normalized {
        case "backdrop": return "w780"
        case "logo": return "w300"
        case "profile": return "w185"
        default: return "w342"
        }
    }

    /// Rewrites the trailing `=wW-hH(-flags)` / `=sN(-flags)` size hint on
    /// googleusercontent URLs (YouTube cover art, channel logos) down to a
    /// preview size, preserving any flags.
    private static func googlePreviewURL(_ urlString: String, imageKind: String) -> String? {
        guard let components = URLComponents(string: urlString),
            let host = components.host,
            host.hasSuffix(".googleusercontent.com")
        else { return nil }
        let size = imageKind.lowercased() == "backdrop" ? 720 : 360
        if let range = urlString.range(of: #"=w\d+-h\d+"#, options: .regularExpression) {
            return urlString.replacingCharacters(in: range, with: "=w\(size)-h\(size)")
        }
        if let range = urlString.range(of: #"=s\d+"#, options: .regularExpression) {
            return urlString.replacingCharacters(in: range, with: "=s\(size)")
        }
        return urlString
    }
}
