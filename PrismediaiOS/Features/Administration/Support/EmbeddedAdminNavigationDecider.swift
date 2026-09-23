import Foundation
import WebKit

#if os(iOS)
    /// Keeps the signed-in administration surface on its configured server.
    @MainActor
    struct EmbeddedAdminNavigationDecider: WebPage.NavigationDeciding {
        let serverURL: URL
        let openExternalURL: (URL) -> Void
        let openEntityLink: (EntityLink) -> Void

        func decidePolicy(
            for action: WebPage.NavigationAction,
            preferences: inout WebPage.NavigationPreferences
        ) async -> WKNavigationActionPolicy {
            guard let url = action.request.url else { return .cancel }
            let sameOrigin = url.scheme == serverURL.scheme
                && url.host == serverURL.host
                && url.port == serverURL.port
            if sameOrigin {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.query = nil
                components?.fragment = nil
                if let detailURL = components?.url,
                   let link = PrismediaEntityDeepLink.link(from: detailURL) {
                    openEntityLink(link)
                    return .cancel
                }
                return .allow
            }
            if action.navigationType == .linkActivated,
               url.scheme == "https" || url.scheme == "http" {
                openExternalURL(url)
            }
            return .cancel
        }
    }
#endif
