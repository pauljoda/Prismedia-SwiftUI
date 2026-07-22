#if os(tvOS)
import SwiftUI

struct TVSignInSurface<FormContent: View, ChangeServer: View, ErrorContent: View, PasswordHelp: View>: View {
    let title: String
    let subtitle: String
    let serverName: String?
    let primaryActionTitle: String
    let primaryActionSystemImage: String
    let isBusy: Bool
    let canSubmit: Bool
    let showsChangeServer: Bool
    let showsPasswordHelp: Bool
    let errorMessage: String?
    let onAdvance: () -> Void
    @ViewBuilder let form: () -> FormContent
    @ViewBuilder let changeServer: () -> ChangeServer
    @ViewBuilder let errorContent: (String) -> ErrorContent
    @ViewBuilder let passwordHelp: () -> PasswordHelp

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    PrismediaBackdrop()

                    HStack(spacing: 96) {
                        identity
                            .frame(maxWidth: 560, alignment: .leading)

                        formPanel
                            .frame(width: 620)
                    }
                    .padding(.horizontal, 112)
                    .padding(.vertical, 72)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                }
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.section) {
            PrismediaBrandView(markSize: PrismediaLayout.televisionBrandMark)

            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Text("PRISMEDIA")
                    .font(.headline.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(PrismediaColor.accent)

                Text("Your library,\nmade cinematic.")
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .lineSpacing(-3)

                Text("Movies, series, and the collections you love—ready for the biggest screen in the house.")
                    .font(.title3)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .lineSpacing(7)
                    .frame(maxWidth: 520, alignment: .leading)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var formPanel: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
            Text(title)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(PrismediaColor.textPrimary)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(PrismediaColor.textSecondary)

            if let serverName {
                Label(serverName, systemImage: "server.rack")
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.accent)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            VStack(alignment: .leading, spacing: PrismediaSpacing.extraExtraLarge) {
                if showsChangeServer {
                    changeServer()
                        .buttonStyle(.plain)
                }

                form()

                if let errorMessage {
                    errorContent(errorMessage)
                }

                PrismediaButton(
                    primaryActionTitle,
                    systemImage: primaryActionSystemImage,
                    variant: .prominent,
                    form: .fill,
                    isLoading: isBusy,
                    action: onAdvance
                )
                .disabled(!canSubmit)
                .accessibilityIdentifier("auth.primary")

                if showsPasswordHelp {
                    passwordHelp()
                        .buttonStyle(.plain)
                }
            }
        }
        .tint(PrismediaColor.accent)
    }
}

#Preview("TV Sign In Surface") {
    TVSignInSurface(
        title: "Sign in",
        subtitle: "Continue to your Prismedia library.",
        serverName: "Living Room Server",
        primaryActionTitle: "Sign In",
        primaryActionSystemImage: "arrow.right",
        isBusy: false,
        canSubmit: true,
        showsChangeServer: true,
        showsPasswordHelp: true,
        errorMessage: nil,
        onAdvance: {},
        form: {
            VStack {
                TextField("Username", text: .constant("alex"))
                SecureField("Password", text: .constant("password"))
            }
        },
        changeServer: { Button("Change Server") {} },
        errorContent: { Text($0) },
        passwordHelp: { Button("Password help") {} }
    )
}
#endif
