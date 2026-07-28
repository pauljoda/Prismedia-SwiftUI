import SwiftUI

struct AppSettingsView: View {
    @Environment(PrismediaAppEnvironment.self) private var environment

    var body: some View {
        Group {
            #if os(macOS)
                MacAppSettingsContentView(showsThumbnailText: showsThumbnailText)
            #else
                Form {
                    EntityThumbnailTextSettingsSection(showsThumbnailText: showsThumbnailText)
                }
            #endif
        }
        .prismediaScreenBackground()
        .navigationTitle("App Settings")
    }

    private var showsThumbnailText: Binding<Bool> {
        Binding(
            get: { environment.entityThumbnailShowsText },
            set: { environment.setEntityThumbnailShowsText($0) }
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
