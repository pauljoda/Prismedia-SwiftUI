import SwiftUI

struct EntityGridSelectionControls: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let selectedCount: Int
    let collectionEligibleCount: Int
    let availableBuiltInActions: Set<EntityGridBuiltInAction>
    let customActions: [EntityGridCustomAction]
    let markNsfwValue: Bool
    let isProcessing: Bool
    let style: EntityGridSelectionControlsStyle
    let onSelectAll: () -> Void
    let onClear: () -> Void
    let onAction: (EntityGridSelectionAction) -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                verticalControls
            } else {
                ViewThatFits(in: .horizontal) {
                    horizontalControls
                        .labelStyle(.titleAndIcon)
                        .fixedSize(horizontal: true, vertical: false)
                    horizontalControls
                        .labelStyle(.iconOnly)
                }
            }
        }
        .controlSize(style == .bottomBar ? .regular : .small)
        .disabled(isProcessing)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("entity.grid.selection.controls")
    }

    private var horizontalControls: some View {
        HStack(spacing: PrismediaSpacing.medium) {
            status

            Spacer(minLength: style == .bottomBar ? PrismediaSpacing.small : 0)

            actionControls
        }
    }

    private var verticalControls: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            status
            selectAllButton
            clearButton
            if selectedCount > 0 {
                actionsMenu
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var status: some View {
        HStack(spacing: PrismediaSpacing.small) {
            Text("\(selectedCount) selected")
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(PrismediaColor.textPrimary)
                .accessibilityIdentifier("entity.grid.selection.count")

            if isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Updating selected items")
            }
        }
    }

    @ViewBuilder
    private var actionControls: some View {
        selectAllButton
        clearButton

        if selectedCount > 0 {
            actionsMenu
        }
    }

    @ViewBuilder
    private var selectAllButton: some View {
        let button = Button("Select All", systemImage: "checkmark.circle") {
            onSelectAll()
        }
        .disabled(isProcessing)
        .accessibilityIdentifier("entity.grid.selection.select-all")

        #if os(tvOS)
            button
        #else
            button.keyboardShortcut("a", modifiers: .command)
        #endif
    }

    private var clearButton: some View {
        Button("Clear", systemImage: "xmark.circle") {
            onClear()
        }
        .disabled(selectedCount == 0 || isProcessing)
        .accessibilityIdentifier("entity.grid.selection.clear")
    }

    private var actionsMenu: some View {
        Menu("Actions", systemImage: "ellipsis.circle") {
            if availableBuiltInActions.contains(.addToCollection) {
                Button(addToCollectionLabel, systemImage: "folder.badge.plus") {
                    onAction(.addToCollection)
                }
            }

            if availableBuiltInActions.contains(.toggleNsfw) {
                Button(markNsfwValue ? "Mark NSFW" : "Mark SFW", systemImage: "flame") {
                    onAction(.markNsfw(markNsfwValue))
                }
            }

            if availableBuiltInActions.contains(.removeWanted) {
                Button("Remove Wanted", systemImage: "bell.slash", role: .destructive) {
                    onAction(.removeWanted)
                }
            }

            if !customActions.isEmpty {
                Divider()
                ForEach(customActions) { action in
                    Button(
                        action.label,
                        systemImage: action.systemImage,
                        role: action.isDestructive ? .destructive : nil
                    ) {
                        onAction(.custom(action.id))
                    }
                }
            }
        }
        .accessibilityIdentifier("entity.grid.selection.actions")
    }

    private var addToCollectionLabel: String {
        guard collectionEligibleCount < selectedCount else { return "Add to Collection" }
        return "Add \(collectionEligibleCount) Eligible to Collection"
    }
}

#if DEBUG
    #Preview("Selection Controls · Compact") {
        EntityGridSelectionControls(
            selectedCount: 3,
            collectionEligibleCount: 2,
            availableBuiltInActions: [.addToCollection, .toggleNsfw, .removeWanted],
            customActions: [],
            markNsfwValue: true,
            isProcessing: false,
            style: .compact,
            onSelectAll: {},
            onClear: {},
            onAction: { _ in }
        )
        .padding()
        .preferredColorScheme(.dark)
    }

    #Preview("Selection Controls · Bottom Bar · Accessibility") {
        EntityGridSelectionControls(
            selectedCount: 12,
            collectionEligibleCount: 12,
            availableBuiltInActions: [.addToCollection, .toggleNsfw],
            customActions: [],
            markNsfwValue: false,
            isProcessing: true,
            style: .bottomBar,
            onSelectAll: {},
            onClear: {},
            onAction: { _ in }
        )
        .padding()
        .environment(\.dynamicTypeSize, .accessibility2)
    }

    #Preview("Selection Controls · Regular · Destructive") {
        let custom = EntityGridCustomAction(
            id: "remove-from-collection",
            label: "Remove from Collection",
            systemImage: "trash",
            isDestructive: true,
            perform: { _ in EntityGridMutationResult() }
        )
        EntityGridSelectionControls(
            selectedCount: 4,
            collectionEligibleCount: 4,
            availableBuiltInActions: [.addToCollection, .removeWanted],
            customActions: [custom],
            markNsfwValue: true,
            isProcessing: false,
            style: .bottomBar,
            onSelectAll: {},
            onClear: {},
            onAction: { _ in }
        )
        .padding()
        .frame(width: 760)
        .preferredColorScheme(.dark)
    }
#endif
