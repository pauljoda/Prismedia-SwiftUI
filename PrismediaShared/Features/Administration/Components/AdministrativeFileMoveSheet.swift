import SwiftUI

#if os(iOS) || os(macOS)
    struct AdministrativeFileMoveSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var targetRootID: UUID
        @State private var path: [AdministrativeFileLocation] = []
        @State private var isMoving = false
        @State private var errorMessage: String?
        let entry: AdministrativeFileEntry
        let roots: [AdministrativeFileRoot]
        let service: any FileAdministrationServicing
        let onMoved: @MainActor () -> Void

        init(
            entry: AdministrativeFileEntry, roots: [AdministrativeFileRoot],
            service: any FileAdministrationServicing, onMoved: @escaping @MainActor () -> Void
        ) {
            self.entry = entry
            self.roots = roots
            self.service = service
            self.onMoved = onMoved
            _targetRootID = State(initialValue: entry.rootID)
        }

        var body: some View {
            NavigationStack(path: $path) {
                destination(rootLocation, allowsRootSelection: true)
                    .navigationDestination(for: AdministrativeFileLocation.self) { location in
                        destination(location, allowsRootSelection: false)
                    }
            }
            .interactiveDismissDisabled(isMoving)
            #if os(macOS)
                .frame(minWidth: 420, minHeight: 440)
            #endif
        }

        private var rootLocation: AdministrativeFileLocation {
            .init(rootID: targetRootID, rootLabel: roots.first { $0.id == targetRootID }?.label ?? "Library", path: "")
        }

        private func destination(_ location: AdministrativeFileLocation, allowsRootSelection: Bool) -> some View {
            AdministrativeFileDestinationList(
                entry: entry, location: location, roots: roots, targetRootID: $targetRootID,
                allowsRootSelection: allowsRootSelection, isMoving: isMoving, errorMessage: errorMessage,
                service: service, cancel: { dismiss() }, move: { Task { await move(into: location) } })
        }

        private func move(into destination: AdministrativeFileLocation) async {
            guard !isMoving else { return }
            isMoving = true
            errorMessage = nil
            defer { isMoving = false }
            do {
                let targetPath = try AdministrativeFilePathPolicy.moveTargetPath(for: entry, into: destination)
                _ = try await service.move(
                    sourceRootID: entry.rootID, sourcePath: entry.path,
                    targetRootID: destination.rootID, targetPath: targetPath)
                onMoved()
                dismiss()
            } catch { errorMessage = error.localizedDescription }
        }
    }
    #if DEBUG
        #Preview {
            AdministrativeFileMoveSheet(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival.mkv", name: "Arrival.mkv", kind: "file", sizeBytes: 1024,
                    mimeType: "video/x-matroska", modifiedAt: nil, excluded: false),
                roots: [
                    .init(
                        id: Step4AdministrationPreviewService.rootID, label: "Movies", path: "/media/movies",
                        enabled: true)
                ],
                service: Step4AdministrationPreviewService(), onMoved: {})
        }
        #Preview("Accessibility") {
            AdministrativeFileMoveSheet(
                entry: .init(
                    rootID: Step4AdministrationPreviewService.rootID,
                    path: "Arrival.mkv", name: "Arrival.mkv", kind: "file", sizeBytes: 1024,
                    mimeType: "video/x-matroska", modifiedAt: nil, excluded: false),
                roots: [
                    .init(
                        id: Step4AdministrationPreviewService.rootID, label: "Movies", path: "/media/movies",
                        enabled: true)
                ],
                service: Step4AdministrationPreviewService(), onMoved: {}
            )
            .environment(\.dynamicTypeSize, .accessibility3)
        }
    #endif
#endif
