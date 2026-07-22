#if os(macOS)
import SwiftUI

struct EntityDetailPlatformActionsView: View {
    let presentation: EntityDetailPresentation
    let isMutating: Bool
    let canMutate: Bool
    let palette: ArtworkPalette?
    let horizontalPadding: CGFloat
    let isActionSupported: (EntityDetailAction) -> Bool
    let isActionEnabled: (EntityDetailAction) -> Bool
    let actionHint: (EntityDetailAction) -> String
    let onRatingChange: (Int?) -> Void
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        let supportedActions = presentation.modificationActions.filter(isActionSupported)
        if !supportedActions.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrismediaSpacing.medium) {
                    ForEach(supportedActions) { action in
                        Button {
                            onAction(action)
                        } label: {
                            Image(systemName: action.isSelected ? selectedImage(for: action) : action.systemImage)
                                .frame(width: 42)
                                .accessibilityHidden(true)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(actionTint(action))
                        .frame(height: 42)
                        .background(
                            PrismediaColor.controlFill.opacity(0.92),
                            in: Circle()
                        )
                        .overlay {
                            Circle().stroke(
                                actionTint(action).opacity(0.32),
                                lineWidth: PrismediaLayout.hairline
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!isActionEnabled(action))
                        .accessibilityLabel(accessibilityLabel(for: action))
                        .accessibilityHint(actionHint(action))
                        .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                        .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
            .prismediaFocusSection()
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Entity actions")
            .accessibilityIdentifier("entity-detail.modification-actions")
        }
    }

    private func selectedImage(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite: "heart.fill"
        case .organized: "checkmark.circle.fill"
        default: action.systemImage
        }
    }

    private func actionTint(_ action: EntityDetailAction) -> Color {
        action.isSelected
            ? palette?.primary.color ?? PrismediaColor.accent
            : palette?.secondary.color ?? PrismediaColor.textSecondary
    }

    private func accessibilityLabel(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite: action.isSelected ? "Remove from favorites" : "Add to favorites"
        case .organized: action.isSelected ? "Mark as unorganized" : "Mark as organized"
        default: action.title
        }
    }
}

#Preview("Mac Entity Detail Actions") {
    EntityDetailPlatformActionsView(
        presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
        isMutating: false,
        canMutate: true,
        palette: nil,
        horizontalPadding: 20,
        isActionSupported: { _ in true },
        isActionEnabled: { _ in true },
        actionHint: { _ in "Updates this entity" },
        onRatingChange: { _ in },
        onAction: { _ in }
    )
    .padding(.vertical)
}
#endif
