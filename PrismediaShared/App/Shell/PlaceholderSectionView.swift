import SwiftUI

public struct PlaceholderSectionView: View {
    let destinationID: String
    let title: String
    let systemImage: String
    let note: String

    public init(destinationID: String, title: String, systemImage: String, note: String) {
        self.destinationID = destinationID
        self.title = title
        self.systemImage = systemImage
        self.note = note
    }

    public init(destination: AppDestination) {
        self.init(
            destinationID: destination.id,
            title: destination.title,
            systemImage: destination.systemImage,
            note: destination.placeholder
        )
    }

    public var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Coming Soon", systemImage: systemImage)
            } description: {
                Text(note)
            }
            .prismediaScreenBackground()
            .navigationTitle(title)
            .prismediaInlineNavigationTitle()
            .accessibilityIdentifier("shell.placeholder.\(destinationID)")
        }
    }
}

#if DEBUG
    #Preview("Native Placeholder") {
        PreviewShell {
            PlaceholderSectionView(destination: ModeCatalog.operate.destinations[0])
        }
    }
#endif
