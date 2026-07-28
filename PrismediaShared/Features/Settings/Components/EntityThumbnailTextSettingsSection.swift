import SwiftUI

struct EntityThumbnailTextSettingsSection: View {
    @Binding var showsThumbnailText: Bool

    var body: some View {
        Section {
            Toggle("Show Text Below Thumbnails", isOn: $showsThumbnailText)
        } header: {
            Label("Entity Grids", systemImage: "rectangle.grid.2x2")
        } footer: {
            Text("Shows each entity’s title, subtitle, and metadata below its artwork.")
        }
    }
}

#if DEBUG
    #Preview("Entity Thumbnail Text Settings") {
        @Previewable @State var showsThumbnailText = true

        Form {
            EntityThumbnailTextSettingsSection(showsThumbnailText: $showsThumbnailText)
        }
        .preferredColorScheme(.dark)
    }
#endif
