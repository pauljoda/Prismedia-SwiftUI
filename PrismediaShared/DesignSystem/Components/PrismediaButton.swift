import SwiftUI

struct PrismediaButton: View {
    let title: String
    let systemImage: String?
    let variant: PrismediaButtonVariant
    let form: PrismediaButtonForm
    let primaryTint: Color?
    let isLoading: Bool
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String? = nil,
        variant: PrismediaButtonVariant = .standard,
        form: PrismediaButtonForm = .automatic,
        primaryTint: Color? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        precondition(
            !form.requiresSystemImage || systemImage != nil,
            "An icon-only button requires a system image."
        )
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.form = form
        self.primaryTint = primaryTint
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        styledButton
            .disabled(isLoading)
            .accessibilityLabel(title)
            .accessibilityValue(isLoading ? "In progress" : "")
    }

    @ViewBuilder
    private var styledButton: some View {
        switch variant {
        case .standard:
            standardGlassButton
        case .prominent:
            if let primaryTint {
                configuredButton
                    .buttonStyle(.glassProminent)
                    .tint(primaryTint)
            } else {
                standardGlassButton
            }
        case .destructive:
            standardGlassButton
                .foregroundStyle(PrismediaColor.destructive)
        }
    }

    private var standardGlassButton: some View {
        configuredButton
            .buttonStyle(.glass)
    }

    private var configuredButton: some View {
        button
            .buttonBorderShape(form.buttonBorderShape)
    }

    private var button: some View {
        Button(role: variant.buttonRole, action: action) {
            buttonLabel
                .padding(.horizontal, PrismediaSpacing.small)
                .padding(.vertical, PrismediaSpacing.extraSmall)
        }
    }

    @ViewBuilder
    private var buttonLabel: some View {
        switch form {
        case .automatic:
            standardLabel
        case .fill:
            standardLabel
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, PrismediaSpacing.large)
                .frame(maxWidth: .infinity)
        case .fillIcon:
            compactIconLabel
                .font(.headline.weight(.bold))
                .padding(.horizontal, PrismediaSpacing.large)
                .frame(maxWidth: .infinity)
        case .compactIcon:
            compactIconLabel
        }
    }

    private var standardLabel: some View {
        Group {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
            } else if let systemImage {
                Label(title, systemImage: systemImage)
            } else {
                Text(title)
            }
        }
    }

    @ViewBuilder
    private var compactIconLabel: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
                .accessibilityHidden(true)
        } else if let systemImage {
            Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
        }
    }
}

#if DEBUG
    #Preview("Prismedia Buttons") {
        ZStack {
            PrismediaBackdrop()

            VStack(spacing: PrismediaSpacing.large) {
                PrismediaButton("Standard", systemImage: "sparkles") {}

                PrismediaButton(
                    "Continue",
                    systemImage: "arrow.right",
                    variant: .prominent,
                    form: .fill,
                    primaryTint: PrismediaColor.spectrumCyan
                ) {}

                PrismediaButton(
                    "Remove",
                    systemImage: "trash",
                    variant: .destructive
                ) {}

                PrismediaButton(
                    "Reader settings",
                    systemImage: "ellipsis",
                    form: .compactIcon
                ) {}

                PrismediaButton(
                    "Continue Reading",
                    systemImage: "book.fill",
                    form: .fillIcon
                ) {}

                PrismediaButton(
                    "Signing In",
                    variant: .prominent,
                    form: .fill,
                    isLoading: true
                ) {}
            }
            .padding(PrismediaSpacing.extraLarge)
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Prismedia Buttons · Accessibility") {
        PrismediaButton(
            "Continue with a deliberately long action title",
            systemImage: "arrow.right",
            variant: .prominent,
            form: .fill
        ) {}
        .padding(PrismediaSpacing.extraLarge)
        .environment(\.dynamicTypeSize, .accessibility4)
        .preferredColorScheme(.dark)
    }
#endif
