import SwiftUI

struct AdministrativeLibraryFolderPicker: View {
    @Environment(\.dismiss) private var dismiss
    let initialPath: String
    let service: any LibraryAdministrationServicing
    let onSelected: (String) -> Void

    var body: some View {
        NavigationStack {
            folder(initialPath)
                .navigationDestination(for: String.self) { path in folder(path) }
        }
        #if os(macOS)
            .frame(minWidth: 420, minHeight: 440)
        #endif
    }

    private func folder(_ path: String) -> some View {
        AdministrativeLibraryFolderList(
            path: path, service: service, cancel: { dismiss() },
            select: { selected in
                onSelected(selected)
                dismiss()
            })
    }
}

#if DEBUG
    #Preview("Server folders") {
        AdministrativeLibraryFolderPicker(
            initialPath: "", service: Step3AdministrationPreviewService(), onSelected: { _ in })
    }
    #Preview("Server folders · Accessibility") {
        AdministrativeLibraryFolderPicker(
            initialPath: "", service: Step3AdministrationPreviewService(), onSelected: { _ in })
            .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
