#if os(iOS) || os(macOS)
    import SwiftUI

    struct EntityImageViewerToolbar: ToolbarContent {
        let title: String
        let positionLabel: String
        let onClose: () -> Void
        let onOpenDetails: () -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", systemImage: "xmark", action: onClose)
                    .accessibilityIdentifier("image-viewer.close")
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(title)
                        .lineLimit(1)
                    Text(positionLabel)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }

            ToolbarItem(placement: .primaryAction) {
                Button("Show Details", systemImage: "info.circle", action: onOpenDetails)
                    .accessibilityIdentifier("image-viewer.details")
                    .accessibilityHint("Opens this image’s metadata and management details")
            }
        }
    }

    #if DEBUG
        #Preview("Image Viewer Toolbar") {
            NavigationStack {
                Color.black
                    .ignoresSafeArea()
                    .toolbar {
                        EntityImageViewerToolbar(
                            title: "Portrait Study",
                            positionLabel: "2 of 6",
                            onClose: {},
                            onOpenDetails: {}
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }
    #endif
#endif
