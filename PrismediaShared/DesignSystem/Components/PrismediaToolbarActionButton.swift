import SwiftUI

/// A compact toolbar action that presents familiar symbols on iOS while
/// preserving its localized title for accessibility and other platforms.
struct PrismediaToolbarActionButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let role: ButtonRole?
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
        }
        .prismediaToolbarActionLabelStyle()
        .accessibilityLabel(title)
    }
}

#Preview {
    NavigationStack {
        Color.clear
            .navigationTitle("Toolbar Action")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Done", systemImage: "checkmark") {}
                }
            }
    }
}
