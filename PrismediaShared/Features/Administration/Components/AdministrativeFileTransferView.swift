import SwiftUI
import UniformTypeIdentifiers

#if os(iOS) || os(macOS)
    struct AdministrativeFileTransferView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var exportDocument: AdministrativeFileExportDocument?
        @State private var showsExporter = false
        @State private var exportError: String?
        let session: AdministrativeFileTransferSession

        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        AdministrativeFileTransferStatusView(
                            title: session.isCancelling ? "Cancelling…" : session.title,
                            detail: session.detail, progress: session.progress,
                            isWorking: session.isWorking)
                    }
                    if let error = exportError ?? session.errorMessage {
                        Section {
                            Text(error).foregroundStyle(PrismediaColor.destructive)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if session.phase == .ready {
                        Section {
                            PrismediaButton(
                                "Save File", systemImage: "square.and.arrow.down", form: .fill,
                                action: prepareExport)
                        }
                    } else if session.canRetry {
                        Section {
                            PrismediaButton("Retry", systemImage: "arrow.clockwise", form: .fill) {
                                Task { await session.run() }
                            }
                        }
                    }
                }
                .prismediaScreenBackground()
                .navigationTitle("Transfer")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        PrismediaToolbarActionButton(
                            session.isWorking ? "Cancel Transfer" : "Done", systemImage: "xmark"
                        ) {
                            if session.isWorking { session.cancel() } else { dismiss() }
                        }.disabled(session.isCancelling && session.isWorking)
                    }
                }
                .task { await session.run() }
                .onChange(of: session.download, initial: true) {
                    if session.download != nil { prepareExport() }
                }
                .fileExporter(
                    isPresented: $showsExporter, document: exportDocument, contentTypes: [.data],
                    defaultFilename: session.download?.suggestedFileName,
                    onCompletion: { result in
                        exportDocument = nil
                        switch result {
                        case .success: dismiss()
                        case .failure(let error): exportError = error.localizedDescription
                        }
                    },
                    onCancellation: { exportDocument = nil })
            }
            .interactiveDismissDisabled(session.isWorking)
            #if os(macOS)
                .frame(minWidth: 400, minHeight: 350)
            #endif
        }

        private func prepareExport() {
            guard let file = session.download else { return }
            exportError = nil
            do {
                exportDocument = try AdministrativeFileExportDocument(sourceURL: file.localURL)
                showsExporter = true
            } catch { exportError = error.localizedDescription }
        }
    }
#endif
