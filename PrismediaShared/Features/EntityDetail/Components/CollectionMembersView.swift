import SwiftUI

/// Platform-shared collection membership surface. The adaptive thumbnail grid
/// keeps native navigation and focus behavior while retaining mixed media in
/// the exact order supplied by the collection endpoint.
struct CollectionMembersView: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    let phase: CollectionMembersPhase
    let horizontalPadding: CGFloat
    let retry: () -> Void

    var body: some View {
        switch phase {
        case .idle, .loading:
            loadingView
        case .content(let members):
            if let group = CollectionMembersPresentation.group(from: members) {
                EntityDetailChildGroupsView(
                    groups: [group],
                    horizontalPadding: horizontalPadding
                )
            } else {
                emptyView
            }
        case .failure(let message):
            failureView(message)
        }
    }

    private var loadingView: some View {
        HStack(spacing: PrismediaSpacing.large) {
            ProgressView()
                .tint(artworkPrimaryAccent)
            Text("Loading collection items…")
                .font(.body)
                .foregroundStyle(artworkSecondaryText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: 180)
        .accessibilityIdentifier("entity-detail.collection.loading")
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "rectangle.stack",
            description: Text("This collection is empty.")
        )
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.collection.empty")
    }

    private func failureView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn’t Load Collection", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            PrismediaButton("Try Again", variant: .prominent, action: retry)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.collection.failure")
    }
}

#if DEBUG

    #Preview("Collection · Mixed Media") {
        NavigationStack {
            ScrollView {
                CollectionMembersView(
                    phase: .content(CollectionMembersPreviewFixture.mixed),
                    horizontalPadding: PrismediaSpacing.extraLarge,
                    retry: {}
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Collection · Loading") {
        CollectionMembersView(phase: .loading, horizontalPadding: PrismediaSpacing.extraLarge, retry: {})
            .preferredColorScheme(.dark)
    }

    #Preview("Collection · Empty · Accessibility") {
        CollectionMembersView(phase: .content([]), horizontalPadding: PrismediaSpacing.extraLarge, retry: {})
            .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview("Collection · Error") {
        CollectionMembersView(
            phase: .failure("The server couldn’t return this collection."),
            horizontalPadding: PrismediaSpacing.extraLarge,
            retry: {}
        )
        .preferredColorScheme(.dark)
    }
#endif
