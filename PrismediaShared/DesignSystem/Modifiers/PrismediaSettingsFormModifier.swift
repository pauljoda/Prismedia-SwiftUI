import SwiftUI

public struct PrismediaSettingsFormModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        #if os(macOS)
            content
                .formStyle(.grouped)
                .contentMargins(.horizontal, PrismediaSpacing.section, for: .scrollContent)
                .contentMargins(.vertical, PrismediaSpacing.extraLarge, for: .scrollContent)
                .frame(maxWidth: 900, maxHeight: .infinity, alignment: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #else
            content
        #endif
    }
}

extension View {
    public func prismediaSettingsForm() -> some View {
        modifier(PrismediaSettingsFormModifier())
    }
}

#if DEBUG
    #Preview("Settings Form") {
        Form {
            Section("Playback") {
                Toggle("Resume automatically", isOn: .constant(true))
                LabeledContent("Quality", value: "Original")
            }
        }
        .modifier(PrismediaSettingsFormModifier())
        .frame(width: 760, height: 520)
        .preferredColorScheme(.dark)
    }
#endif
