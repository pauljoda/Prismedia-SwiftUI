#if os(tvOS)
import SwiftUI

struct EntityDetailPlatformActionsView: View {
    let presentation: EntityDetailPresentation
    let palette: ArtworkPalette?
    let horizontalPadding: CGFloat
    let isActionSupported: (EntityDetailAction) -> Bool
    let isActionEnabled: (EntityDetailAction) -> Bool
    let actionHint: (EntityDetailAction) -> String
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        let supportedActions = presentation.modificationActions.filter(isActionSupported)
        if !supportedActions.isEmpty {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Text("Library Controls")
                    .font(.title2.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: PrismediaSpacing.section) {
                        ForEach(supportedActions) { action in
                            Button {
                                onAction(action)
                            } label: {
                                Label(
                                    accessibilityLabel(for: action),
                                    systemImage: action.isSelected
                                        ? selectedImage(for: action)
                                        : action.systemImage
                                )
                                .font(.headline)
                                .padding(.horizontal, PrismediaSpacing.medium)
                                .frame(minHeight: 66)
                            }
                            .buttonStyle(.glass)
                            .foregroundStyle(
                                action.isSelected
                                    ? palette?.primary.color ?? PrismediaColor.accent
                                    : PrismediaColor.onMedia
                            )
                            .disabled(!isActionEnabled(action))
                            .accessibilityHint(actionHint(action))
                            .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                            .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                        }
                    }
                    .padding(.vertical, PrismediaSpacing.large)
                }
                .prismediaFocusSection()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Library controls")
                .accessibilityIdentifier("entity-detail.modification-actions")
            }
            .padding(.horizontal, horizontalPadding)
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
        palette: nil,
        horizontalPadding: 72,
        isActionSupported: { _ in true },
        isActionEnabled: { _ in true },
        actionHint: { _ in "Updates this entity" },
        onAction: { _ in }
    )
}
#endif
