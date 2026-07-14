import SwiftUI

struct PreviewShell<Content: View>: View {
    @State private var environment: PrismediaAppEnvironment
    @State private var router: PrismediaAppRouter
    private let content: Content

    @MainActor
    init(
        signedIn: Bool = false,
        initialMode: AppMode = ModeCatalog.overview,
        initialSelection: String? = nil,
        initialSearchSelected: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        _environment = State(
            initialValue: PrismediaPreviewData.model(signedIn: signedIn)
        )
        _router = State(
            initialValue: PrismediaAppRouter(
                initialMode: initialMode,
                initialDestinationID: initialSelection,
                initialSearchSelected: initialSearchSelected
            ))
        self.content = content()
    }

    var body: some View {
        content
            .environment(environment)
            .environment(router)
            .tint(PrismediaColor.accent)
            .preferredColorScheme(.dark)
    }
}

#if DEBUG
    #Preview("Deterministic Preview Fixtures") {
        PreviewShell {
            ScrollView {
                VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
                    LabeledContent("Preview Account", value: PrismediaPreviewData.user.displayName)
                        .foregroundStyle(PrismediaColor.textPrimary)

                    EntityThumbnailCardView(
                        item: PrismediaPreviewData.videos[0],
                        layout: .wall
                    )

                    HStack(alignment: .top, spacing: PrismediaSpacing.large) {
                        EntityThumbnailCardView(item: PrismediaPreviewData.series)
                        EntityThumbnailCardView(item: PrismediaPreviewData.book)
                    }
                }
                .padding(PrismediaSpacing.extraLarge)
            }
            .background(PrismediaBackdrop())
        }
    }
#endif
