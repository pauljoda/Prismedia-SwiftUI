import SwiftUI

struct AccountSessionRow: View {
    let session: AccountSession
    let isWorking: Bool
    let onRevoke: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
            Image(systemName: session.isCurrent ? "iphone.gen3" : "display")
                .foregroundStyle(session.isCurrent ? PrismediaColor.accent : PrismediaColor.textSecondary)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Text(title)
                HStack {
                    if session.isCurrent { Text("This device").foregroundStyle(.tint) }
                    Text("Active \(session.lastSeenAt, format: .relative(presentation: .named))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if let version = session.applicationVersion {
                    Text("Version \(version)").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Button(session.isCurrent ? "Sign Out" : "Revoke", role: .destructive, action: onRevoke)
                .disabled(isWorking)
        }
        .accessibilityElement(children: .combine)
    }

    private var title: String {
        [session.client, session.deviceName].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: " · ")
            .nilIfEmpty ?? "Unknown device"
    }
}

extension String {
    fileprivate var nilIfEmpty: String? { isEmpty ? nil : self }
}

#if DEBUG
    #Preview {
        AccountSessionRow(
            session: AccountSession(
                id: UUID(),
                client: "Prismedia for iOS",
                deviceName: "Preview iPhone",
                applicationVersion: "1.0",
                createdAt: .now.addingTimeInterval(-86_400),
                lastSeenAt: .now,
                isCurrent: true
            ),
            isWorking: false,
            onRevoke: {}
        )
        .padding()
    }
#endif
