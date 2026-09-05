import SwiftUI

struct AdministrativeFileRootRow: View {
    let root: AdministrativeFileRoot

    var body: some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.medium) {
            Image(systemName: root.enabled ? "externaldrive.fill" : "externaldrive.badge.xmark")
                .foregroundStyle(PrismediaColor.textSecondary)
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text(root.label).font(.headline)
                Text(root.path)
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PrismediaSpacing.small)
        .accessibilityElement(children: .combine)
    }
}
