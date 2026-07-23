import SwiftUI

struct SignInHeader: View {
    let title: String
    let subtitle: String
    let serverName: String?
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            PrismediaBrandView(
                markSize: isCompact
                    ? PrismediaLayout.compactBrandMark
                    : PrismediaLayout.brandMark
            )
            .frame(maxWidth: .infinity)

            Text(title)
                .font(isCompact ? .title.bold() : .largeTitle.bold())
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let serverName {
                Label(serverName, systemImage: "server.rack")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
}

#if DEBUG
    #Preview("Sign In Header · Server") {
        SignInHeader(
            title: "Connect to Prismedia",
            subtitle: "Enter the address you use to open your library.",
            serverName: nil,
            isCompact: false
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Sign In Header · Connected Compact") {
        SignInHeader(
            title: "Welcome back",
            subtitle: "Sign in to continue to your library.",
            serverName: "prismedia.example.com",
            isCompact: true
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
    }

    #Preview("Sign In Header · Accessibility") {
        SignInHeader(
            title: "Set up Prismedia",
            subtitle: "Create the administrator account for this server.",
            serverName: "a-very-long-server-name.example.com",
            isCompact: false
        )
        .frame(maxWidth: SignInLayout.maximumFormWidth)
        .padding(PrismediaSpacing.extraLarge)
        .background(PrismediaBackdrop())
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
