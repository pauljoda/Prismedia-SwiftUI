import SwiftUI

struct AdministrativePluginDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showsCredentials = false
    @State private var confirmsRemoval = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    let plugin: AdministrativePlugin
    let service: any PluginAdministrationServicing
    let onChanged: @MainActor () -> Void

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
                Section("Capabilities") {
                    ForEach(plugin.supports, id: \.entityKind) { support in
                        VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                            Text(support.contentTypeLabel).font(.headline)
                            Text(support.actionSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if !plugin.auth.isEmpty {
                    Section("Credentials") {
                        LabeledContent(
                            "Readiness",
                            value: plugin.missingAuthKeys.isEmpty
                                ? "Ready" : "Missing \(plugin.missingAuthKeys.count) required field(s)"
                        )
                        Button("Configure Credentials", systemImage: "key") { showsCredentials = true }
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
            .disabled(isWorking)
            .prismediaScreenBackground()
            .navigationTitle(plugin.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Done", systemImage: "checkmark") { dismiss() }
                }
            }
            .overlay { if isWorking { ProgressView("Updating provider…") } }
            .sheet(isPresented: $showsCredentials) {
                AdministrativePluginCredentialEditor(plugin: plugin, service: service) {
                    onChanged()
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
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
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
        await mutate { _ = try await PluginAdministrationUseCase(service: service).install(id: plugin.id) }
    }
    private func update() async {
        await mutate { _ = try await PluginAdministrationUseCase(service: service).update(id: plugin.id) }
    }
    private func remove() async {
        await mutate { try await PluginAdministrationUseCase(service: service).remove(id: plugin.id) }
        if errorMessage == nil { dismiss() }
    }

    private func mutate(_ operation: @escaping @MainActor () async throws -> Void) async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await operation()
            onChanged()
        } catch { errorMessage = error.localizedDescription }
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
