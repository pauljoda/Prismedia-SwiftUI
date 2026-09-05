import SwiftUI

struct AdministrativeUserRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let user: UserAccount
    let isCurrent: Bool
    let isWorking: Bool
    var canEdit = true
    let libraryCount: Int
    let onEdit: () -> Void
    let onPassword: () -> Void
    let onToggleEnabled: () -> Void
    let onDelete: () -> Void

    var body: some View {
        let identityLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: PrismediaSpacing.extraSmall))
            : AnyLayout(HStackLayout(spacing: PrismediaSpacing.small))
        HStack(spacing: PrismediaSpacing.medium) {
            Image(systemName: user.isAdmin ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                .font(.title2)
                .foregroundStyle(user.enabled ? PrismediaColor.accent : PrismediaColor.textSecondary)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                identityLayout {
                    Text(user.displayName).font(.headline)
                    HStack(spacing: PrismediaSpacing.small) {
                        if user.isAdmin { Text("Admin").font(.caption2).foregroundStyle(PrismediaColor.warning) }
                        if isCurrent { Text("You").font(.caption2).foregroundStyle(.tint) }
                    }
                }
                Text("@\(user.username) · \(accessSummary)")
                    .font(.caption.monospaced()).foregroundStyle(.secondary)
                if let lastLoginAt = user.lastLoginAt {
                    Text("Last sign-in \(lastLoginAt, format: .dateTime.year().month().day())")
                        .font(.caption2).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Menu("User Actions", systemImage: "ellipsis.circle") {
                Button("Edit", systemImage: "pencil", action: onEdit)
                    .disabled(!canEdit)
                Button("Reset Password", systemImage: "key", action: onPassword)
                Button(user.enabled ? "Disable" : "Enable", systemImage: "power", action: onToggleEnabled)
                    .disabled(isCurrent)
                Divider()
                Button("Delete User", systemImage: "trash", role: .destructive, action: onDelete)
                    .disabled(isCurrent)
            }
            .labelStyle(.iconOnly)
            .disabled(isWorking)
        }
        .opacity(user.enabled ? 1 : PrismediaOpacity.disabled)
    }

    private var accessSummary: String {
        if user.isAdmin { return "All libraries" }
        let count = user.libraryRootIDs?.count ?? 0
        if count == 0 { return "No libraries" }
        if count == libraryCount && libraryCount > 0 { return "All libraries" }
        return "\(count) librar\(count == 1 ? "y" : "ies")"
    }
}

#if DEBUG
    #Preview("User · Accessibility") {
        AdministrativeUserRow(
            user: PrismediaPreviewData.user,
            isCurrent: true,
            isWorking: false,
            libraryCount: 2,
            onEdit: {}, onPassword: {}, onToggleEnabled: {}, onDelete: {}
        )
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
    }

    #Preview {
        AdministrativeUserRow(
            user: PrismediaPreviewData.user,
            isCurrent: true,
            isWorking: false,
            libraryCount: 2,
            onEdit: {},
            onPassword: {},
            onToggleEnabled: {},
            onDelete: {}
        )
        .padding()
    }
#endif
