import SwiftUI

struct AdministrativeDestinationView: View {
    let destination: AdministrativeDestination
    let service: any AdministrationServicing
    let hidesNsfw: Bool

    var body: some View {
        switch destination {
        case .plugins: AdministrativePluginsView(service: service, hidesNsfw: hidesNsfw)
        case .jobs: AdministrativeJobsView(service: service)
        case .settings: AdministrativeSettingsView(service: service)
        }
    }
}

#if DEBUG
    #Preview {
        AdministrativeDestinationView(
            destination: .plugins,
            service: AdministrativePreviewService(),
            hidesNsfw: true
        )
    }
#endif
