import SwiftUI
import WebKit

#if os(iOS)
    /// Presents the server's responsive administration content inside native navigation.
    struct EmbeddedAdminContentView: View {
        @Environment(\.openURL) private var openURL
        @Environment(PrismediaAppEnvironment.self) private var environment
        @Environment(PrismediaAppRouter.self) private var router
        @State private var page: WebPage?
        @State private var loadError: String?

        let session: AuthSession
        let path: String

        var body: some View {
            Group {
                if let page {
                    WebView(page)
                        .background(PrismediaColor.background)
                } else if let loadError {
                    ContentUnavailableView(
                        "Could not open administration",
                        systemImage: "wifi.exclamationmark",
                        description: Text(loadError)
                    )
                } else {
                    ProgressView("Opening administration")
                }
            }
            .task(id: session.accessToken + path) {
                await openContent()
            }
            .onChange(of: page?.url) { _, url in
                guard url?.path == "/restore" else { return }
                Task { await environment.beginDatabaseRestore() }
            }
            .onDisappear { environment.entityDidMutate() }
        }

        private func openContent() async {
            page = nil
            loadError = nil
            guard session.serverURL.host != nil,
                  session.serverURL.scheme == "http" || session.serverURL.scheme == "https",
                  let url = URL(string: path, relativeTo: session.serverURL)?.absoluteURL
            else {
                loadError = "The server address is invalid."
                return
            }

            let dataStore = WKWebsiteDataStore.nonPersistent()
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: "prismedia-session",
                .value: session.accessToken,
                .originURL: session.serverURL,
                .path: "/",
                .sameSitePolicy: "Lax",
                HTTPCookiePropertyKey("HttpOnly"): "TRUE",
            ]
            if session.serverURL.scheme == "https" {
                properties[.secure] = "TRUE"
            }
            guard let cookie = HTTPCookie(properties: properties) else {
                loadError = "The web session could not be created."
                return
            }
            await dataStore.httpCookieStore.setCookie(cookie)

            var configuration = WebPage.Configuration()
            configuration.websiteDataStore = dataStore
            let webPage = WebPage(
                configuration: configuration,
                navigationDecider: EmbeddedAdminNavigationDecider(
                    serverURL: session.serverURL,
                    openExternalURL: { url in openURL(url) },
                    openEntityLink: { link in router.openLinkedEntity(link) }
                )
            )
            page = webPage
            _ = webPage.load(url)
        }
    }
#endif
