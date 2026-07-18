import SwiftUI

struct EntityDetailPrimaryActionsView: View {
    @Environment(\.artworkPalette) private var artworkPalette
    #if os(tvOS)
        @FocusState private var focusedActionID: EntityDetailActionID?
    #endif
    let actions: [EntityDetailAction]
    let horizontalPadding: CGFloat
    let isEnabled: (EntityDetailAction) -> Bool
    let accessibilityHint: (EntityDetailAction) -> String
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        if !actions.isEmpty {
            #if os(tvOS)
                HStack(spacing: PrismediaSpacing.section) {
                    actionButtons
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, horizontalPadding)
                .prismediaFocusSection()
                .defaultFocus($focusedActionID, defaultActionID)
                .task(id: defaultActionID) {
                    guard let defaultActionID else { return }
                    await Task.yield()
                    focusedActionID = defaultActionID
                }
            #else
                VStack(spacing: PrismediaSpacing.medium) {
                    actionButtons
                }
                .padding(.horizontal, horizontalPadding)
            #endif
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        ForEach(actions) { action in
            let isTinted = action.id == EntityDetailPrimaryActionPolicy.tintedActionID(in: actions)
            PrismediaButton(
                action.title,
                systemImage: action.systemImage,
                variant: isTinted ? .prominent : .standard,
                form: .fill,
                primaryTint: isTinted ? primaryTint : nil
            ) {
                onAction(action)
            }
            .disabled(!isEnabled(action))
            #if os(tvOS)
                .frame(maxWidth: 520)
                .focused($focusedActionID, equals: action.id)
            #endif
            .accessibilityLabel(action.title)
            .accessibilityHint(accessibilityHint(action))
            .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
        }
    }

    private var primaryTint: Color {
        artworkPalette?.primary.color ?? PrismediaColor.accent
    }

    #if os(tvOS)
        private var defaultActionID: EntityDetailActionID? {
            actions.first(where: { $0.id == .play })?.id
                ?? actions.first(where: { $0.id == .resume })?.id
                ?? actions.first?.id
        }
    #endif
}

#if DEBUG
    #Preview("Entity Detail · Primary Action") {
        EntityDetailPrimaryActionsView(
            actions: [
                EntityDetailAction(
                    id: .resume,
                    title: "Resume",
                    systemImage: "play.fill",
                    isSelected: false,
                    isPrimary: true
                )
            ],
            horizontalPadding: PrismediaSpacing.extraLarge,
            isEnabled: { _ in true },
            accessibilityHint: { _ in "Resumes playback" },
            onAction: { _ in }
        )
        .padding(.vertical, PrismediaSpacing.extraLarge)
        .preferredColorScheme(.dark)
    }
#endif
