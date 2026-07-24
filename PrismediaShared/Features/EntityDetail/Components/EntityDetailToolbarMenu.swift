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
            ControlGroup {
                ForEach(commonActions) { action in
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
                    .accessibilityIdentifier("entity-detail.action.\(action.id.rawValue)")
                }

                Button(action: onAddToCollection) {
                    Label("Collection", systemImage: "folder.badge.plus")
                }
                .accessibilityLabel("Add to Collection")
                .accessibilityIdentifier("entity-detail.add-to-collection")
            }

            if !stateActions.isEmpty {
                Divider()

                ForEach(stateActions) { action in
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

    private var commonActions: [EntityDetailAction] {
        [.identify, .edit].compactMap { id in
            actions.first { $0.id == id }
        }
    }

    private var stateActions: [EntityDetailAction] {
        actions.filter { $0.id == .favorite || $0.id == .organized }
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
