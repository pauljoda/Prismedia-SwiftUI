import SwiftUI

struct EntityDetailToolbarMenu: View {
    let actions: [EntityDetailAction]
    let isEnabled: (EntityDetailAction) -> Bool
    let accessibilityLabel: (EntityDetailAction) -> String
    let accessibilityHint: (EntityDetailAction) -> String
    let onAddToCollection: () -> Void
    let onAction: (EntityDetailAction) -> Void

    var body: some View {
        Menu {
            Button(action: onAddToCollection) {
                Label("Add to Collection", systemImage: "folder.badge.plus")
            }
            .accessibilityIdentifier("entity-detail.add-to-collection")

            if !actions.isEmpty {
                Divider()

                ForEach(actions) { action in
                    Button {
                        onAction(action)
                    } label: {
                        Label(
                            accessibilityLabel(action),
                            systemImage: actionSystemImage(action)
                        )
                    }
                    .disabled(!isEnabled(action))
                    .accessibilityHint(accessibilityHint(action))
                    .accessibilityAddTraits(action.isSelected ? .isSelected : [])
                    .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                }
            }
        } label: {
            Label("More actions", systemImage: "ellipsis")
                .labelStyle(.iconOnly)
        }
        .accessibilityLabel("More actions")
        .accessibilityIdentifier("entity-detail.more-actions")
    }

    private func actionSystemImage(_ action: EntityDetailAction) -> String {
        guard action.isSelected else { return action.systemImage }
        switch action.id {
        case .favorite:
            return "heart.fill"
        case .organized:
            return "checkmark.circle.fill"
        default:
            return action.systemImage
        }
    }
}

#if DEBUG
    #Preview("Entity Detail Toolbar Menu") {
        EntityDetailToolbarMenu(
            actions: [
                EntityDetailAction(
                    id: .favorite,
                    title: "Favorite",
                    systemImage: "heart",
                    isSelected: true,
                    isPrimary: false
                ),
                EntityDetailAction(
                    id: .organized,
                    title: "Mark organized",
                    systemImage: "checkmark.circle",
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
        .preferredColorScheme(.dark)
    }
#endif
