import SwiftUI

struct PrismediaTextFieldStyle: TextFieldStyle {
    let surface: PrismediaControlSurface

    @ViewBuilder
    func _body(configuration: TextField<Self._Label>) -> some View {
        #if os(tvOS)
            configuration
        #else
            switch surface {
            case .floating:
                fieldLayout(configuration)
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(cornerRadius: PrismediaRadius.control)
                    )
            case .embedded:
                fieldLayout(configuration)
                    .background(
                        PrismediaColor.controlFill,
                        in: .rect(cornerRadius: PrismediaRadius.control)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: PrismediaRadius.control, style: .continuous)
                            .stroke(PrismediaColor.border, lineWidth: PrismediaLayout.hairline)
                    }
            }
        #endif
    }

    private func fieldLayout(_ configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, PrismediaSpacing.medium)
            .padding(.vertical, PrismediaSpacing.small)
            .frame(minHeight: PrismediaLayout.minimumHitTarget)
    }
}

extension View {
    @ViewBuilder
    func prismediaTextInputStyle(
        surface: PrismediaControlSurface = .floating
    ) -> some View {
        #if os(tvOS)
            textFieldStyle(.automatic)
        #else
            textFieldStyle(PrismediaTextFieldStyle(surface: surface))
        #endif
    }
}

#if DEBUG
    #Preview("Prismedia Text Fields") {
        @Previewable @State var title = "Signal in the Static"
        @Previewable @State var password = "prismedia"

        ZStack {
            PrismediaBackdrop()

            VStack(spacing: PrismediaSpacing.large) {
                TextField("Title", text: $title)
                    .textFieldStyle(PrismediaTextFieldStyle(surface: .floating))

                SecureField("Password", text: $password)
                    .prismediaTextInputStyle(surface: .floating)

                TextField("Embedded field", text: $title)
                    .prismediaTextInputStyle(surface: .embedded)
                    .disabled(true)
            }
            .padding(PrismediaSpacing.extraLarge)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Prismedia Text Field · Accessibility") {
        @Previewable @State var value = "Long-form metadata value"

        TextField("Metadata", text: $value, axis: .vertical)
            .lineLimit(2...4)
            .textFieldStyle(PrismediaTextFieldStyle(surface: .floating))
            .padding(PrismediaSpacing.extraLarge)
            .environment(\.dynamicTypeSize, .accessibility3)
            .preferredColorScheme(.dark)
    }
#endif
