#if os(iOS) || os(macOS)
    import SwiftUI

    struct EntityGridSelectionToolbar: ToolbarContent {
        let selectedCount: Int
        let collectionEligibleCount: Int
        let availableBuiltInActions: Set<EntityGridBuiltInAction>
        let customActions: [EntityGridCustomAction]
        let markNsfwValue: Bool
        let isProcessing: Bool
        let onSelectAll: () -> Void
        let onClear: () -> Void
        let onAction: (EntityGridSelectionAction) -> Void

        @ToolbarContentBuilder
        var body: some ToolbarContent {
            #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    selectAllButton
                }

                ToolbarItem(placement: .principal) {
                    selectionStatus
                }

                ToolbarItem(placement: .topBarTrailing) {
                    actionsMenu
                }
            #else
                ToolbarItemGroup(placement: .primaryAction) {
                    selectionStatus
                    selectAllButton
                    clearButton
                    if selectedCount > 0 {
                        actionsMenu
                    }
                }
            #endif
        }

        private var selectionStatus: some View {
            HStack(spacing: PrismediaSpacing.small) {
                Text("\(selectedCount) selected")
                    .monospacedDigit()
                    .accessibilityIdentifier("entity.grid.selection.count")

                if isProcessing {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Updating selected items")
                }
            }
            .accessibilityElement(children: .combine)
        }

        private var selectAllButton: some View {
            #if os(iOS)
                let button = Button("Select All", action: onSelectAll)
            #else
                let button = Button("Select All", systemImage: "checkmark.circle", action: onSelectAll)
            #endif
            return
                button
                .disabled(isProcessing)
                .keyboardShortcut("a", modifiers: .command)
                .accessibilityIdentifier("entity.grid.selection.select-all")
        }

        private var clearButton: some View {
            Button("Clear", systemImage: "xmark.circle", action: onClear)
                .disabled(selectedCount == 0 || isProcessing)
                .accessibilityIdentifier("entity.grid.selection.clear")
        }

        private var actionsMenu: some View {
            Menu("Actions", systemImage: "ellipsis.circle") {
                #if os(iOS)
                    clearButton

                    if selectedCount > 0 {
                        Divider()
                    }
                #endif

                if selectedCount > 0 {
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
            }
            .disabled(isProcessing)
            .accessibilityIdentifier("entity.grid.selection.actions")
        }

        private var addToCollectionLabel: String {
            guard collectionEligibleCount < selectedCount else { return "Add to Collection" }
            return "Add \(collectionEligibleCount) Eligible to Collection"
        }
    }

    #if DEBUG
        #Preview("Selection Toolbar · Mixed Eligibility") {
            NavigationStack {
                Color.clear
                    .navigationTitle("Movies")
                    .toolbar {
                        EntityGridSelectionToolbar(
                            selectedCount: 3,
                            collectionEligibleCount: 2,
                            availableBuiltInActions: [.addToCollection, .toggleNsfw],
                            customActions: [],
                            markNsfwValue: true,
                            isProcessing: false,
                            onSelectAll: {},
                            onClear: {},
                            onAction: { _ in }
                        )
                    }
            }
            .preferredColorScheme(.dark)
        }

        #Preview("Selection Toolbar · Destructive · Accessibility") {
            let removal = EntityGridCustomAction(
                id: "remove-from-collection",
                label: "Remove from Collection",
                systemImage: "trash",
                isDestructive: true,
                perform: { _ in EntityGridMutationResult() }
            )
            NavigationStack {
                Color.clear
                    .navigationTitle("Collection")
                    .toolbar {
                        EntityGridSelectionToolbar(
                            selectedCount: 4,
                            collectionEligibleCount: 4,
                            availableBuiltInActions: [.addToCollection, .removeWanted],
                            customActions: [removal],
                            markNsfwValue: false,
                            isProcessing: false,
                            onSelectAll: {},
                            onClear: {},
                            onAction: { _ in }
                        )
                    }
            }
            .environment(\.dynamicTypeSize, .accessibility2)
        }
    #endif
#endif
