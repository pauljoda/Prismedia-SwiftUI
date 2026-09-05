import SwiftUI

/// Local actions for a changed text setting, wrapping vertically when their labels need more room.
struct AdministrativeSettingTextActions: View {
    let settingLabel: String
    let isSaving: Bool
    let canSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            PrismediaGlassButtonGroup { actions }
            PrismediaGlassButtonStack(alignment: .trailing) { actions }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private var actions: some View {
        PrismediaButton("Cancel", action: onCancel)
            .disabled(isSaving)
            .accessibilityHint("Discard changes to \(settingLabel)")
        PrismediaButton(
            "Save", variant: .prominent, primaryTint: PrismediaColor.accent,
            isLoading: isSaving, loadingTitle: "Saving…", action: onSave
        )
        .disabled(!canSave)
        .accessibilityHint("Save changes to \(settingLabel)")
    }
}

#if DEBUG
    #Preview("Setting Actions · Large Text") {
        Form {
            AdministrativeSettingTextActions(
                settingLabel: "Tool path", isSaving: false, canSave: true, onCancel: {}, onSave: {}
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
