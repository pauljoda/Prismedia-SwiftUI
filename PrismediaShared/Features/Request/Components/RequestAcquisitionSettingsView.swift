import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestAcquisitionSettingsView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var section: AdministrativeSettingsSection?
        @State private var isLoading = true
        @State private var message: String?

        let service: any AdministrationServicing

        var body: some View {
            NavigationStack {
                Group {
                    if let section {
                        AdministrativeSettingsDetailView(
                            section: section,
                            cacheStatus: nil,
                            onSave: save,
                            onClearCache: { nil },
                            onCreateBackup: { false }
                        )
                    } else if isLoading {
                        PrismediaLoadingView("Loading acquisition settings…")
                    } else {
                        ContentUnavailableView(
                            "Acquisition Settings Unavailable",
                            systemImage: "slider.horizontal.3",
                            description: Text(message ?? "The server did not return acquisition settings.")
                        )
                    }
                }
                .navigationTitle("Acquisition Settings")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel("Close")
                    }
                }
            }
            .task { await load() }
            .alert("Settings", isPresented: messageIsPresented) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(message ?? "")
            }
        }

        private var messageIsPresented: Binding<Bool> {
            Binding(
                get: { message != nil && section != nil },
                set: { if !$0 { message = nil } }
            )
        }

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do {
                let catalog = try await service.settings()
                section = AdministrativeSettingsSectionCatalog.sections(for: catalog)
                    .first { $0.id == "acquisition" }
                message = nil
            } catch {
                section = nil
                message = error.localizedDescription
            }
        }

        private func save(
            setting: AdministrativeSetting,
            value: AdministrativeJSONValue
        ) async -> AdministrativeSettingsSection? {
            do {
                _ = try await service.updateSetting(key: setting.key, value: value)
                let catalog = try await service.settings()
                let updated = AdministrativeSettingsSectionCatalog.sections(for: catalog)
                    .first { $0.id == "acquisition" }
                section = updated
                return updated
            } catch {
                message = error.localizedDescription
                return nil
            }
        }
    }

    #if DEBUG
        #Preview("Acquisition Settings · Empty") {
            RequestAcquisitionSettingsView(service: AdministrativePreviewService())
        }
    #endif
#endif
