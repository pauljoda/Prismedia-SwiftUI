import SwiftUI

struct AdministrativeDestinationView: View {
    let destination: AdministrativeDestination
    let service: any AdministrationServicing
    let pluginService: any PluginAdministrationServicing
    let client: PrismediaAPIClient
    let user: UserAccount
    let hidesNsfw: Bool
    let onRestoreScheduled: () async -> Void

    init(
        destination: AdministrativeDestination,
        service: any AdministrationServicing,
        client: PrismediaAPIClient,
        user: UserAccount,
        hidesNsfw: Bool,
        onRestoreScheduled: @escaping () async -> Void,
        pluginService: (any PluginAdministrationServicing)? = nil
    ) {
        self.destination = destination
        self.service = service
        self.client = client
        self.user = user
        self.hidesNsfw = hidesNsfw
        self.onRestoreScheduled = onRestoreScheduled
        if let pluginService {
            self.pluginService = pluginService
        } else {
            #if DEBUG
                self.pluginService =
                    PrismediaUITestBootstrap.usesStep4AdministrationFixtures()
                    ? Step4AdministrationPreviewService()
                    : PluginAdministrationService(client: client)
            #else
                self.pluginService = PluginAdministrationService(client: client)
            #endif
        }
    }

    var body: some View {
        switch destination {
        case .plugins: AdministrativePluginsView(service: pluginService, hidesNsfw: hidesNsfw)
        case .jobs: AdministrativeJobsView(service: service)
        case .settings:
            AdministrativeSettingsView(
                service: service,
                user: user,
                hidesNsfw: hidesNsfw,
                libraryService: LibraryAdministrationService(client: client),
                userService: UserAdministrationService(client: client),
                diagnosticsService: DiagnosticsService(client: client),
                backupService: DatabaseBackupService(client: client),
                onRestoreScheduled: onRestoreScheduled
            )
        }
    }
}

#if DEBUG
    #Preview {
        AdministrativeDestinationView(
            destination: .plugins,
            service: AdministrativePreviewService(),
            client: PrismediaAPIClient(serverURL: URL(string: "https://preview.invalid")!),
            user: PrismediaPreviewData.user,
            hidesNsfw: true,
            onRestoreScheduled: {},
            pluginService: Step4AdministrationPreviewService()
        )
    }
#endif
