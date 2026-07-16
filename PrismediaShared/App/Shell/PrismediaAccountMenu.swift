import SwiftUI

struct PrismediaAccountMenu: View {
    let user: UserAccount
    let allowsNsfwContent: Bool
    let onOpenAccount: () -> Void
    let onOpenSettings: (() -> Void)?
    let onSetAllowsNsfwContent: @MainActor @Sendable (Bool) -> Void
    let onSignOut: () -> Void

    var body: some View {
        Menu {
            Section {
                Label(user.displayName, systemImage: "person.crop.circle")
                Text("@\(user.username)")
            }

            Button("Account", systemImage: "person.crop.circle", action: onOpenAccount)

            if let onOpenSettings {
                Button("Settings", systemImage: "gearshape", action: onOpenSettings)
            }

            if user.allowNsfw {
                Toggle(
                    "Allow NSFW Content",
                    isOn: Binding(
                        get: { allowsNsfwContent },
                        set: onSetAllowsNsfwContent
                    )
                )
                .accessibilityIdentifier("shell.account.allowNsfw")
            }

            Divider()

            Button(
                "Sign Out",
                systemImage: "rectangle.portrait.and.arrow.right",
                role: .destructive,
                action: onSignOut
            )
        } label: {
            Text(accountInitials)
                .font(.caption.bold())
                .foregroundStyle(PrismediaColor.onAccent.opacity(0.82))
                .frame(width: 34, height: 34)
                .background(PrismediaColor.accent.gradient, in: Circle())
        }
        .accessibilityLabel("Account, \(user.displayName)")
        .accessibilityIdentifier("shell.account")
    }

    private var accountInitials: String {
        let parts = user.displayName
            .split(whereSeparator: \.isWhitespace)
            .prefix(2)
        let initials = parts.compactMap(\.first).map(String.init).joined()
        return initials.isEmpty ? String(user.username.prefix(1)).uppercased() : initials.uppercased()
    }
}

#if DEBUG
    #Preview("Account Menu") {
        PrismediaAccountMenu(
            user: PrismediaPreviewData.user,
            allowsNsfwContent: false,
            onOpenAccount: {},
            onOpenSettings: {},
            onSetAllowsNsfwContent: { _ in },
            onSignOut: {}
        )
        .padding()
        .preferredColorScheme(.dark)
    }
#endif
