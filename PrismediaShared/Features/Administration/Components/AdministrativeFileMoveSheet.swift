import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileMoveSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var targetRootID: UUID
        @State private var targetPath: String
        @State private var isMoving = false
        @State private var errorMessage: String?
        let entry: AdministrativeFileEntry
        let roots: [AdministrativeFileRoot]
        let service: any FileAdministrationServicing
        let onMoved: @MainActor () -> Void

        init(
            entry: AdministrativeFileEntry,
            roots: [AdministrativeFileRoot],
            service: any FileAdministrationServicing,
            onMoved: @escaping @MainActor () -> Void
        ) {
            self.entry = entry
            self.roots = roots
            self.service = service
            self.onMoved = onMoved
            _targetRootID = State(initialValue: entry.rootID)
            _targetPath = State(initialValue: entry.path)
        }

        var body: some View {
            NavigationStack {
                Form {
                    Section("Destination") {
                        Picker("Library Root", selection: $targetRootID) {
                            ForEach(roots) { root in Text(root.label).tag(root.id) }
                        }
                        TextField("Relative path including name", text: $targetPath)
                            .autocorrectionDisabled()
                    }
                    Section {
                        Text(
                            "The server moves the filesystem item and rewrites known linked source paths. Existing destinations are rejected, not overwritten."
                        )
                    }
                }
                .navigationTitle("Move \(entry.name)")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Move") { Task { await move() } }
                            .disabled(isMoving)
                    }
                }
                .overlay { if isMoving { ProgressView("Moving…") } }
                .alert(
                    "Move Failed",
                    isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }
            }
            .frame(minWidth: 360, minHeight: 300)
        }

        private func move() async {
            isMoving = true
            defer { isMoving = false }
            do {
                _ = try await service.move(
                    sourceRootID: entry.rootID,
                    sourcePath: entry.path,
                    targetRootID: targetRootID,
                    targetPath: targetPath
                )
                onMoved()
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }

    #if DEBUG
        #Preview("Move File") {
            AdministrativeFileMoveSheet(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival/Arrival.mkv",
                    name: "Arrival.mkv",
                    kind: "file",
                    sizeBytes: 1_024,
                    mimeType: "video/x-matroska",
                    modifiedAt: nil,
                    excluded: false
                ),
                roots: [
                    .init(
                        id: Step4AdministrationPreviewService.rootID, label: "Movies", path: "/media/movies",
                        enabled: true)
                ],
                service: Step4AdministrationPreviewService(),
                onMoved: {}
            )
        }
    #endif
#endif
