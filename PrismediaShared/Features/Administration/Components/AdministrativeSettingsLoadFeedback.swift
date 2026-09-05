import SwiftUI

struct AdministrativeSettingsLoadFeedback: View {
    let session: AdministrativeSettingsLoadSession
    let service: any AdministrationServicing

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            if let error = session.catalog.errorMessage {
                PrismediaRetryView(
                    title: "Couldn't Load Server Settings",
                    message: "Reload server settings before editing them. \(error)",
                    retry: { Task { await session.load(service: service) } })
            } else {
                if session.catalog.isLoading {
                    ProgressView("Loading server settings…")
                }
                if let error = session.cache.errorMessage {
                    PrismediaRetryView(
                        title: "Cache Status Unavailable", message: error,
                        retry: { Task { await session.loadCache(service: service) } })
                }
                if let error = session.plugins.errorMessage {
                    PrismediaRetryView(
                        title: "Provider Choices Unavailable",
                        message: "Other settings are still available. \(error)",
                        retry: { Task { await session.loadPlugins(service: service) } })
                }
                if !session.catalog.isLoading && (session.cache.isLoading || session.plugins.isLoading) {
                    ProgressView("Loading supporting information…")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
    #Preview("Settings Load Failure") {
        @Previewable @State var session = AdministrativeSettingsLoadSession()
        Form {
            AdministrativeSettingsLoadFeedback(session: session, service: AdministrativePreviewService())
        }
        .task { await session.load(service: AdministrativePreviewService(settingsUnavailable: true)) }
    }
#endif
