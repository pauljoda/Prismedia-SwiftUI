import SwiftUI

struct AppSettingsView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment

    var body: some View {
        Form {
            EntityGridCardStyleSettingsSection(cardStyle: cardStyle)
        }
        .prismediaScreenBackground()
        .navigationTitle("App Settings")
    }

    private var cardStyle: Binding<EntityGridCardStyle> {
        Binding(
            get: { environment.entityGridCardStyle },
            set: { environment.setEntityGridCardStyle($0) }
        )
    }
}

#if DEBUG
    #Preview("App Settings") {
        PreviewShell {
            NavigationStack {
                AppSettingsView()
            }
        }
    }
#endif
