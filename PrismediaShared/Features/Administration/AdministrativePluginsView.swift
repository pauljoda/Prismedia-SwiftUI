import SwiftUI

struct AdministrativePluginsView: View {
    @State private var plugins: [AdministrativePlugin] = []
    @State private var isLoading = true
    @State private var updatingPluginID: String?
    @State private var errorMessage: String?
    private let service: any AdministrationServicing

    init(service: any AdministrationServicing) { self.service = service }

    var body: some View {
        NavigationStack {
            List(plugins) { plugin in
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    HStack {
                        Text(plugin.name)
                        Spacer()
                        Text(plugin.version).font(.caption).foregroundStyle(.secondary)
                    }
                    Text(plugin.supports.map(\.entityKind).joined(separator: ", ")).font(.caption).foregroundStyle(
                        .secondary)
                    if !plugin.missingAuthKeys.isEmpty {
                        Label("Credentials required", systemImage: "key.fill").font(.caption).foregroundStyle(
                            PrismediaColor.warning)
                    }
                    if plugin.updateAvailable {
                        Button("Update to \(plugin.availableVersion ?? "latest")", systemImage: "arrow.down.circle") {
                            Task { await update(plugin) }
                        }
                        .disabled(updatingPluginID != nil)
                    }
                }
            }
            .prismediaScreenBackground()
            .overlay {
                if isLoading && plugins.isEmpty {
                    PrismediaLoadingView("Loading plugins…")
                } else if isLoading {
                    ProgressView("Loading plugins…")
                } else if plugins.isEmpty {
                    ContentUnavailableView(
                        "No Compatible Plugins", systemImage: "puzzlepiece.extension",
                        description: Text("Install plugins on the server to use metadata and request providers."))
                }
            }
            .navigationTitle("Plugins")
            .refreshable { await load() }
            .alert(
                "Plugin Action Failed",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
        .task { await load() }
        .accessibilityIdentifier("administration.plugins")
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do { plugins = try await service.plugins() } catch { errorMessage = error.localizedDescription }
    }

    private func update(_ plugin: AdministrativePlugin) async {
        updatingPluginID = plugin.id
        defer { updatingPluginID = nil }
        do {
            let updated = try await service.updatePlugin(id: plugin.id)
            if let index = plugins.firstIndex(where: { $0.id == updated.id }) { plugins[index] = updated }
        } catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
    #Preview { AdministrativePluginsView(service: AdministrativePreviewService()) }
#endif
