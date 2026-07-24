#if DEBUG && (os(iOS) || os(macOS))
    import SwiftUI

    #Preview("Request & Identify Review · Entry · Entity Menu") {
        EntityDetailToolbarMenu(
            actions: [
                EntityDetailAction(
                    id: .favorite,
                    title: "Add to favorites",
                    systemImage: "heart",
                    isSelected: false,
                    isPrimary: false
                ),
                EntityDetailAction(
                    id: .organized,
                    title: "Mark organized",
                    systemImage: "checkmark.circle",
                    isSelected: false,
                    isPrimary: false
                ),
                EntityDetailAction(
                    id: .edit,
                    title: "Edit",
                    systemImage: "pencil",
                    isSelected: false,
                    isPrimary: false
                ),
                EntityDetailAction(
                    id: .identify,
                    title: "Identify",
                    systemImage: "doc.viewfinder",
                    isSelected: false,
                    isPrimary: false
                ),
            ],
            isEnabled: { _ in true },
            accessibilityLabel: { $0.title },
            accessibilityHint: { _ in "Updates this entity" },
            onAddToCollection: {},
            onAction: { _ in }
        )
        .padding()
        .preferredColorScheme(.dark)
    }

    #Preview("Request & Identify Review · Entry · Pending Queue") {
        EntityDetailToolbarMenu(
            actions: [
                EntityDetailAction(
                    id: .edit,
                    title: "Edit",
                    systemImage: "pencil",
                    isSelected: false,
                    isPrimary: false
                ),
                EntityDetailAction(
                    id: .identify,
                    title: "Pending Review",
                    systemImage: "clock",
                    isSelected: false,
                    isPrimary: false
                ),
            ],
            isEnabled: { _ in true },
            accessibilityLabel: { $0.title },
            accessibilityHint: { _ in "Resumes the durable Identify queue item" },
            onAddToCollection: {},
            onAction: { _ in }
        )
        .padding()
        .preferredColorScheme(.dark)
    }

    #Preview("Request & Identify Review · Entry · Initial Loading") {
        RequestIdentifyFlowSheet(
            mode: .identify,
            phase: .initialDependencyLoading
        ) {
            PrismediaLoadingView("Preparing identify search…")
                .navigationTitle("Identify")
        }
    }

    #Preview("Request & Identify Review · Entry · Unavailable") {
        RequestIdentifyFlowSheet(
            mode: .identify,
            phase: .unavailable
        ) {
            ContentUnavailableView {
                Label("Identify Unavailable", systemImage: "puzzlepiece.extension")
            } description: {
                Text("Install or configure a compatible Identify plugin to continue.")
            } actions: {
                Button("Open Plugins", systemImage: "puzzlepiece.extension") {}
            }
            .navigationTitle("Identify")
        }
    }

    #Preview("Request & Identify Review · Entry · Search Error") {
        EntityIdentifyFlowView(
            session: IdentifySession(
                service: AdministrativePreviewService(),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [IdentifyPreviewFixtures.errorItem],
                initialProviders: [IdentifyPreviewFixtures.provider]
            ),
            entityID: IdentifyPreviewFixtures.errorItem.entityID,
            automaticallyBegins: false,
            onIdentified: {}
        )
    }

    #Preview("Request & Identify Review · Entry · Review Ready") {
        EntityIdentifyFlowView(
            session: IdentifySession(
                service: AdministrativePreviewService(),
                browser: IdentifyPreviewEntityBrowser(),
                initialQueue: [IdentifyPreviewFixtures.reviewItem],
                initialProviders: [IdentifyPreviewFixtures.provider]
            ),
            entityID: IdentifyPreviewFixtures.reviewItem.entityID,
            automaticallyBegins: false,
            onIdentified: {}
        )
    }

    #Preview("Request & Identify Review · Entry · Committing") {
        RequestIdentifyFlowSheet(
            mode: .identify,
            phase: .committing
        ) {
            PrismediaLoadingView("Applying identification…")
                .navigationTitle("Identify")
        }
    }

    #Preview("Request & Identify Review · Entry · Request Review") {
        RequestIdentifyFlowSheet(
            mode: .request,
            phase: .reviewReady,
            showsBackToSearch: true
        ) {
            RequestReviewView(
                service: RequestPreviewService(scenario: .content),
                route: RequestPreviewFixtures.route,
                hidesNsfw: true,
                flowPhase: .constant(.reviewReady),
                onNavigateToEntity: { _ in }
            )
        }
    }

    #Preview("Request & Identify Review · Entry · Safe Unknown State") {
        RequestIdentifyFlowSheet(
            mode: .identify,
            phase: .unknown("waiting-for-provider")
        ) {
            ContentUnavailableView {
                Label("Waiting for Identify", systemImage: "hourglass")
            } description: {
                Text("This queue item reported a newer server state. Refresh or resume it from the Identify queue.")
            }
            .navigationTitle("Identify")
        }
    }
#endif
