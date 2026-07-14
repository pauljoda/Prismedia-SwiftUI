import SwiftUI

struct AdministrativeDestinationView: View {
    let destination: AdministrativeDestination
    let service: any AdministrationServicing

    var body: some View {
        switch destination {
        case .plugins: AdministrativePluginsView(service: service)
        case .jobs: AdministrativeJobsView(service: service)
        case .settings: AdministrativeSettingsView(service: service)
        }
    }
}

#if DEBUG
    #Preview {
        AdministrativeDestinationView(
            destination: .plugins,
            service: AdministrativePreviewService()
        )
    }
#endif
