import SwiftUI

struct RequestActivitySelectionToggle: View {
    let isEditing: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isEditing ? "checkmark" : "checkmark.circle")
        }
        .accessibilityLabel(isEditing ? "Done Selecting" : "Select Items")
    }
}

#if DEBUG
    #Preview("Request Activity Selection Toggle") {
        PrismediaGlassButtonGroup(spacing: PrismediaSpacing.medium) {
            RequestActivitySelectionToggle(isEditing: false, onToggle: {})
            RequestActivitySelectionToggle(isEditing: true, onToggle: {})
        }
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }
#endif
