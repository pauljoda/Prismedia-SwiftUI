import SwiftUI

struct AdministrativePluginDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsCredentials = false
    @State private var confirmsRemoval = false
    @State private var session: PluginManagementSession
    let service: any PluginAdministrationServicing
    let onChanged: @MainActor () -> Void

    init(
        plugin: AdministrativePlugin, service: any PluginAdministrationServicing,
        onChanged: @escaping @MainActor () -> Void
    ) {
        _session = State(initialValue: PluginManagementSession(plugin: plugin, service: service))
        self.service = service
        self.onChanged = onChanged
    }

    private var plugin: AdministrativePlugin { session.plugin }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent(
                        "Status", value: plugin.installed ? (plugin.enabled ? "Installed" : "Disabled") : "Available"
                    )
                    LabeledContent("Version", value: plugin.version)
                    if plugin.updateAvailable {
                        LabeledContent("Available Update", value: plugin.availableVersion ?? "Latest")
                    }
                }
                if let message = session.refreshError {
                    Section {
                        Label("Couldn't refresh provider status", systemImage: "exclamationmark.triangle")
                        Text(message).font(.subheadline).foregroundStyle(.secondary)
                        Button("Retry", systemImage: "arrow.clockwise") { Task { await session.refresh() } }
                    }
                }
                if !plugin.auth.isEmpty {
                    Section("Credentials") {
                        Label(
                            plugin.missingAuthKeys.isEmpty ? "Ready" : "Setup required",
                            systemImage: plugin.missingAuthKeys.isEmpty ? "checkmark.circle" : "key"
                        )
                        if !plugin.missingAuthKeys.isEmpty {
                            Text(
                                plugin.auth.filter { plugin.missingAuthKeys.contains($0.key) }.map(\.label).joined(
                                    separator: ", ")
                            )
                            .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Button("Edit Credentials", systemImage: "key") { showsCredentials = true }
                    }
                }
                if !plugin.supports.isEmpty {
                    Section {
                        AdministrativePluginCapabilitiesView(supports: plugin.supports)
                    }
                }
                Section("Actions") {
                    if !plugin.installed || !plugin.enabled {
                        Button(
                            plugin.installed ? "Enable Provider" : "Install Provider", systemImage: "arrow.down.circle"
                        ) {
                            Task { await install() }
                        }
                    }
                    if plugin.installed, plugin.updateAvailable {
                        Button(
                            "Update to \(plugin.availableVersion ?? "Latest")",
                            systemImage: "arrow.trianglehead.2.clockwise"
                        ) {
                            Task { await update() }
                        }
                    }
                    if plugin.installed {
                        Button("Remove Provider", systemImage: "trash", role: .destructive) { confirmsRemoval = true }
                    }
                }
                #if os(tvOS)
                    Section("Technical Details") { technicalDetails }
                #else
                    Section {
                        DisclosureGroup("Technical Details") { technicalDetails }
                    }
                #endif
            }
            .disabled(session.isWorking)
            .prismediaScreenBackground()
            .navigationTitle(plugin.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Done", systemImage: "checkmark") { dismiss() }
                        .disabled(session.isWorking)
                }
            }
            .overlay { if session.isWorking { ProgressView("Updating provider…") } }
            .interactiveDismissDisabled(session.isWorking)
            .sheet(isPresented: $showsCredentials) {
                AdministrativePluginCredentialEditor(plugin: plugin, service: service) {
                    Task {
                        await session.refresh()
                        onChanged()
                    }
                }
            }
            .alert("Remove \(plugin.name)?", isPresented: $confirmsRemoval) {
                Button("Remove Provider", role: .destructive) { Task { await remove() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(
                    "This removes installed configuration and immediately removes the provider from Request and Identify choices. Plugin files remain on the server."
                )
            }
            .alert(
                "Plugin Action Failed",
                isPresented: Binding(
                    get: { session.errorMessage != nil }, set: { if !$0 { session.errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(session.errorMessage ?? "")
            }
        }
        #if os(macOS)
            .frame(minWidth: 380, minHeight: 520)
        #endif
    }

    @ViewBuilder
    private var technicalDetails: some View {
        LabeledContent("Provider ID", value: plugin.id)
        LabeledContent(
            "Source", value: plugin.id.hasPrefix("stash-") ? "Stash Community" : "Prismedia Community")
        LabeledContent("Content", value: plugin.isNsfw ? "NSFW" : "SFW")
    }

    private func install() async {
        if await session.install() { onChanged() }
    }
    private func update() async {
        if await session.update() { onChanged() }
    }
    private func remove() async {
        if await session.remove() {
            onChanged()
            dismiss()
        }
    }
}

#if DEBUG
    #Preview("Plugin · Update and Auth") {
        AdministrativePluginDetailView(
            plugin: AdministrativePlugin(
                id: "tmdb", name: "TMDB", version: "1.1.0", installed: true, enabled: true, isNsfw: false,
                supports: [.init(entityKind: "movie", actions: ["search", "lookup-id"])],
                auth: [.init(key: "api_key", label: "API Key", required: true, url: nil)],
                missingAuthKeys: ["api_key"], updateAvailable: true, availableVersion: "1.2.0"
            ),
            service: Step4AdministrationPreviewService(),
            onChanged: {}
        )
    }
#endif
