import SwiftUI

struct EntityGridSelectionToggle: View {
    let isActive: Bool
    let isDisabled: Bool
    let onToggle: () -> Void

    var body: some View {
        let button = Button(action: onToggle) {
            Image(systemName: isActive ? "checkmark" : "checkmark.circle")
        }
        .disabled(isDisabled)
        .accessibilityLabel(isActive ? "Done Selecting" : "Select Items")
        .accessibilityIdentifier("entity.grid.selection.toggle")

        #if os(macOS)
            button.keyboardShortcut("s", modifiers: [.command, .shift])
        #else
            button
        #endif
    }
}

#if DEBUG
    #Preview("Entity Grid Selection · States") {
        PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
            EntityGridSelectionToggle(
                isActive: false,
                isDisabled: false,
                onToggle: {}
            )
            EntityGridSelectionToggle(
                isActive: true,
                isDisabled: false,
                onToggle: {}
            )
            EntityGridSelectionToggle(
                isActive: false,
                isDisabled: true,
                onToggle: {}
            )
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
