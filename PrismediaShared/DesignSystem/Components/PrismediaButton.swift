import SwiftUI

struct PrismediaButton: View {
    let title: String
    let systemImage: String?
    let variant: PrismediaButtonVariant
    let form: PrismediaButtonForm
    let primaryTint: Color?
    let isLoading: Bool
    let loadingTitle: String?
    let action: () -> Void
    private let menuContent: (() -> AnyView)?

    init(
        _ title: String,
        systemImage: String? = nil,
        variant: PrismediaButtonVariant = .standard,
        form: PrismediaButtonForm = .automatic,
        primaryTint: Color? = nil,
        isLoading: Bool = false,
        loadingTitle: String? = nil,
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
        self.loadingTitle = loadingTitle
        self.action = action
        menuContent = nil
    }

    init<MenuContent: View>(
        _ title: String,
        systemImage: String,
        variant: PrismediaButtonVariant = .standard,
        form: PrismediaButtonForm = .automatic,
        primaryTint: Color? = nil,
        @ViewBuilder menuContent: @escaping () -> MenuContent
    ) {
        precondition(
            !form.requiresSystemImage || !systemImage.isEmpty,
            "An icon-only menu requires a system image."
        )
        self.title = title
        self.systemImage = systemImage
        self.variant = variant
        self.form = form
        self.primaryTint = primaryTint
        isLoading = false
        loadingTitle = nil
        action = {}
        self.menuContent = { AnyView(menuContent()) }
    }

    var body: some View {
        styledButton
            .disabled(isLoading)
            .accessibilityLabel(title)
            .accessibilityValue(isLoading ? "In progress" : "")
            .help(title)
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

    @ViewBuilder
    private var button: some View {
        if let menuContent {
            Menu {
                menuContent()
            } label: {
                paddedButtonLabel
            }
        } else {
            Button(role: variant.buttonRole, action: action) {
                paddedButtonLabel
            }
        }
    }

    private var paddedButtonLabel: some View {
        buttonLabel
            .padding(.horizontal, PrismediaSpacing.small)
            .padding(.vertical, PrismediaSpacing.extraSmall)
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
                if let loadingTitle {
                    HStack(spacing: PrismediaSpacing.small) {
                        ProgressView()
                            .controlSize(.small)
                            .accessibilityHidden(true)
                        Text(loadingTitle)
                    }
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityHidden(true)
                }
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
