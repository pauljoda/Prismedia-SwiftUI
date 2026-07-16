import SwiftUI

struct AdministrativeDestinationView: View {
    let destination: AdministrativeDestination
    let service: any AdministrationServicing
    let client: PrismediaAPIClient
    let user: UserAccount
    let hidesNsfw: Bool
    let onRestoreScheduled: () async -> Void

    var body: some View {
        switch destination {
        case .plugins: AdministrativePluginsView(service: service, hidesNsfw: hidesNsfw)
        case .jobs: AdministrativeJobsView(service: service)
        case .settings:
            AdministrativeSettingsView(
                service: service,
                user: user,
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
            onRestoreScheduled: {}
        )
    }
#endif
