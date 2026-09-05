import SwiftUI

/// A catalog entry emphasizes the provider, supported content, and actionable readiness.
struct AdministrativePluginCatalogRow: View {
    let plugin: AdministrativePlugin

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(plugin.name).font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            Text(plugin.supports.map(\.contentTypeLabel).joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                Label(
                    plugin.installed ? (plugin.enabled ? "Installed" : "Disabled") : "Available",
                    systemImage: plugin.installed ? "checkmark.circle" : "arrow.down.circle"
                )
                .foregroundStyle(.secondary)
                if plugin.updateAvailable {
                    Label("Update available", systemImage: "arrow.trianglehead.2.clockwise")
                }
                if !plugin.missingAuthKeys.isEmpty {
                    Label("Credentials required", systemImage: "key.fill")
                        .foregroundStyle(PrismediaColor.warning)
                }
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
    #Preview("Plugin Catalog · Large Text") {
        List {
            AdministrativePluginCatalogRow(
                plugin: .init(
                    id: "preview", name: "Metadata Provider", version: "1.0", installed: true,
                    enabled: true, isNsfw: false,
                    supports: [.init(entityKind: EntityKind.movie.rawValue, actions: [])],
                    missingAuthKeys: ["credential"], updateAvailable: true, availableVersion: "1.1"
                )
            )
        }
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
