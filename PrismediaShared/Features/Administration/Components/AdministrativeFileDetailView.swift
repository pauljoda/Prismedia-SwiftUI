import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileDetailView: View {
        @State private var detail: AdministrativeFileDetail?
        @State private var isLoading = true
        @State private var errorMessage: String?
        let entry: AdministrativeFileEntry
        let service: any FileAdministrationServicing

        var body: some View {
            Form {
                Section("File") {
                    LabeledContent("Name", value: entry.name)
                    LabeledContent("Type", value: entry.isDirectory ? "Folder" : (entry.mimeType ?? "File"))
                    if let size = entry.sizeBytes {
                        LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                    }
                    LabeledContent("Scan Status", value: entry.excluded ? "Excluded" : "Included")
                }
                if let detail {
                    Section("Server") {
                        LabeledContent("Path", value: detail.absolutePath)
                        if let count = detail.directoryFileCount {
                            LabeledContent("Files", value: count.formatted())
                        }
                        if let total = detail.directoryTotalSizeBytes {
                            LabeledContent(
                                "Recursive Size",
                                value: ByteCountFormatter.string(fromByteCount: total, countStyle: .file))
                        }
                    }
                    Section("Linked Library Entities") {
                        if detail.linkedEntities.isEmpty {
                            Text(entry.excluded ? "Excluded paths are intentionally unlinked." : "No linked entities.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(detail.linkedEntities) { entity in
                                LabeledContent(entity.title, value: entity.kind)
                            }
                        }
                    }
                }
            }
            .navigationTitle(entry.name)
            .overlay { if isLoading { ProgressView() } }
            .task(id: entry.id) { await load() }
            .alert(
                "Details Unavailable",
                isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }

        private func load() async {
            isLoading = true
            defer { isLoading = false }
            do { detail = try await service.detail(rootID: entry.rootID, path: entry.path) } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
        #Preview("File Detail") {
            AdministrativeFileDetailView(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival/Arrival.mkv",
                    name: "Arrival.mkv",
                    kind: "file",
                    sizeBytes: 8_589_934_592,
                    mimeType: "video/x-matroska",
                    modifiedAt: Date(),
                    excluded: false
                ),
                service: Step4AdministrationPreviewService()
            )
            .frame(width: 360, height: 600)
        }
    #endif
#endif
