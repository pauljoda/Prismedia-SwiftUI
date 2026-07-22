#if os(tvOS)
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
        Group {
            if presentation.hasRatingCapability {
                EntityDetailStarRatingControl(
                    value: presentation.rating,
                    isDisabled: isMutating || !canMutate,
                    onChange: onRatingChange
                )
                .padding(.horizontal, horizontalPadding)
                .prismediaFocusSection()
            }

            let supportedActions = presentation.modificationActions.filter(isActionSupported)
            if !supportedActions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PrismediaSpacing.section) {
                        ForEach(supportedActions) { action in
                            Button {
                                onAction(action)
                            } label: {
                                Image(systemName: action.isSelected ? selectedImage(for: action) : action.systemImage)
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 64, height: 58)
                            }
                            .buttonStyle(.glass)
                            .foregroundStyle(
                                action.isSelected
                                    ? palette?.primary.color ?? PrismediaColor.accent
                                    : PrismediaColor.onMedia
                            )
                            .disabled(!isActionEnabled(action))
                            .accessibilityLabel(accessibilityLabel(for: action))
                            .accessibilityHint(actionHint(action))
                            .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                            .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, PrismediaSpacing.large)
                }
                .prismediaFocusSection()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Entity actions")
                .accessibilityIdentifier("entity-detail.modification-actions")
            }
        }
    }

    private func selectedImage(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite: "heart.fill"
        case .organized: "checkmark.circle.fill"
        default: action.systemImage
        }
    }

    private func accessibilityLabel(for action: EntityDetailAction) -> String {
        switch action.id {
        case .favorite: action.isSelected ? "Remove from favorites" : "Add to favorites"
        case .organized: action.isSelected ? "Mark as unorganized" : "Mark as organized"
        default: action.title
        }
    }
}

#Preview("TV Entity Detail Actions") {
    EntityDetailPlatformActionsView(
        presentation: EntityDetailPresentation(detail: EntityDetailPreviewFixture.detail),
        isMutating: false,
        canMutate: true,
        palette: nil,
        horizontalPadding: 72,
        isActionSupported: { _ in true },
        isActionEnabled: { _ in true },
        actionHint: { _ in "Updates this entity" },
        onRatingChange: { _ in },
        onAction: { _ in }
    )
}
#endif
