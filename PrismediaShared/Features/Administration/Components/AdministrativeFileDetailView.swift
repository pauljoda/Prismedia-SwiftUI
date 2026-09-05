import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct AdministrativeFileDetailView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var detail: AdministrativeFileDetail?
        @State private var isLoading = true
        @State private var errorMessage: String?
        let entry: AdministrativeFileEntry
        let service: any FileAdministrationServicing
        var onAction: (AdministrativeFileAction) -> Void = { _ in }

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        Text(entry.name).font(.headline).fixedSize(horizontal: false, vertical: true)
                        LabeledContent("Type", value: typeLabel)
                        if let size = entry.sizeBytes {
                            LabeledContent(
                                "Size", value: ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                        }
                        LabeledContent("Scan Status", value: entry.excluded ? "Excluded" : "Included")
                        if let modified = entry.modifiedAt {
                            LabeledContent("Modified", value: modified.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    if let errorMessage {
                        Section {
                            PrismediaRetryView(
                                title: "Couldn't Load Details", message: errorMessage,
                                isRetrying: isLoading, retry: { Task { await load() } })
                        }
                    }
                    if let detail {
                        Section("Server") {
                            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                                Text("Path").font(.subheadline)
                                Text(detail.absolutePath).foregroundStyle(.secondary)
                                    .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                            }
                            if let count = detail.directoryFileCount {
                                LabeledContent("Files", value: count.formatted())
                            }
                            if let total = detail.directoryTotalSizeBytes {
                                LabeledContent(
                                    "Total Size",
                                    value: ByteCountFormatter.string(fromByteCount: total, countStyle: .file))
                            }
                        }
                        Section("Linked Items") {
                            if detail.linkedEntities.isEmpty {
                                Text(entry.excluded ? "Excluded from the library." : "No linked items.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(detail.linkedEntities) { entity in
                                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                                        Text(entity.title).fixedSize(horizontal: false, vertical: true)
                                        Text(EntityKind(rawValue: entity.kind).displayLabel)
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else if isLoading {
                        Section { ProgressView("Loading details…") }
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle(entry.isDirectory ? "Folder Details" : "File Details")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        PrismediaToolbarActionButton("Done", systemImage: "xmark") { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu("File Actions", systemImage: "ellipsis") {
                            AdministrativeFileActions(entry: entry, includesDetails: false, perform: onAction)
                        }.prismediaToolbarActionLabelStyle()
                    }
                }
                .task(id: entry.id) { await load() }
            }
            #if os(macOS)
                .frame(minWidth: 400, minHeight: 480)
            #endif
        }

        private var typeLabel: String {
            if entry.isDirectory { return "Folder" }
            let fileExtension = URL(fileURLWithPath: entry.name).pathExtension
            return UTType(filenameExtension: fileExtension)?.localizedDescription ?? "File"
        }

        private func load() async {
            guard !Task.isCancelled else { return }
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            do {
                let loaded = try await service.detail(rootID: entry.rootID, path: entry.path)
                guard !Task.isCancelled else { return }
                detail = loaded
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                errorMessage = error.localizedDescription
            }
        }
    }
    #if DEBUG
        #Preview {
            AdministrativeFileDetailView(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival.mkv", name: "Arrival.mkv", kind: "file", sizeBytes: 1024,
                    mimeType: "video/x-matroska", modifiedAt: nil, excluded: false),
                service: Step4AdministrationPreviewService())
        }
        #Preview("Accessibility") {
            AdministrativeFileDetailView(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival.mkv", name: "Arrival.mkv", kind: "file", sizeBytes: 1024,
                    mimeType: "video/x-matroska", modifiedAt: nil, excluded: false),
                service: Step4AdministrationPreviewService()
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
