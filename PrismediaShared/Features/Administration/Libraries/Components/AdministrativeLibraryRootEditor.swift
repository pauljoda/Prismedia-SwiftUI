import SwiftUI

struct AdministrativeLibraryRootEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var path: String
    @State private var label: String
    @State private var enabled: Bool
    @State private var recursive: Bool
    @State private var scanVideos: Bool
    @State private var scanImages: Bool
    @State private var scanAudio: Bool
    @State private var scanBooks: Bool
    @State private var isNsfw: Bool
    @State private var autoIdentify: Bool
    @State private var selectedUserIDs: Set<UUID>
    @State private var showsFolderPicker = false
    @State private var isWorking = false
    @State private var error: String?
    let target: AdministrativeLibraryEditorTarget
    let availableUsers: [UserAccount]
    let allowsNsfw: Bool
    let isAdministrator: Bool
    let service: any LibraryAdministrationServicing
    let onSaved: (AdministrativeLibraryRoot) -> Void

    init(
        target: AdministrativeLibraryEditorTarget,
        availableUsers: [UserAccount],
        allowsNsfw: Bool,
        isAdministrator: Bool,
        service: any LibraryAdministrationServicing,
        onSaved: @escaping (AdministrativeLibraryRoot) -> Void
    ) {
        self.target = target
        self.availableUsers = availableUsers
        self.allowsNsfw = allowsNsfw
        self.isAdministrator = isAdministrator
        self.service = service
        self.onSaved = onSaved
        let root = target.root
        _path = State(initialValue: root?.path ?? "")
        _label = State(initialValue: root?.label ?? "")
        _enabled = State(initialValue: root?.enabled ?? true)
        _recursive = State(initialValue: root?.recursive ?? true)
        _scanVideos = State(initialValue: root?.scanVideos ?? true)
        _scanImages = State(initialValue: root?.scanImages ?? true)
        _scanAudio = State(initialValue: root?.scanAudio ?? true)
        _scanBooks = State(initialValue: root?.scanBooks ?? false)
        _isNsfw = State(initialValue: root?.isNsfw ?? false)
        _autoIdentify = State(initialValue: root?.autoIdentify ?? true)
        _selectedUserIDs = State(initialValue: Set(root?.accessUserIDs ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text("Server path").font(.subheadline).foregroundStyle(.secondary)
                        TextField("Choose or enter a folder", text: $path, axis: .vertical)
                            .prismediaPlainTextInput()
                    }
                    Button("Browse Server Folders", systemImage: "folder") { showsFolderPicker = true }
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        Text("Name").font(.subheadline).foregroundStyle(.secondary)
                        TextField("Optional library name", text: $label)
                    }
                }
                Section("Scanning") {
                    Toggle("Scan this library", isOn: $enabled)
                    Toggle("Include subfolders", isOn: $recursive)
                    Toggle("Identify automatically", isOn: $autoIdentify)
                }
                Section {
                    Toggle("Videos", isOn: $scanVideos)
                    Toggle("Images", isOn: $scanImages)
                    Toggle("Audio", isOn: $scanAudio)
                    Toggle("Books", isOn: $scanBooks)
                } header: {
                    Text("Media Types")
                } footer: {
                    if ![scanVideos, scanImages, scanAudio, scanBooks].contains(true) {
                        Text("Choose at least one media type to save the library.")
                    }
                    if scanBooks && scanImages {
                        Text("ZIP and CBZ files can appear as both books and image galleries.")
                            .font(.footnote).foregroundStyle(PrismediaColor.warning)
                    }
                }
                if allowsNsfw {
                    Section("Content") { Toggle("NSFW Library", isOn: $isNsfw) }
                }
                if isAdministrator && availableUsers.contains(where: { !$0.isAdmin }) {
                    Section("Member Access") {
                        ForEach(availableUsers.filter { !$0.isAdmin }) { user in
                            let isSelected = Binding(
                                get: { selectedUserIDs.contains(user.id) },
                                set: { newValue in
                                    if newValue {
                                        selectedUserIDs.insert(user.id)
                                    } else {
                                        selectedUserIDs.remove(user.id)
                                    }
                                }
                            )
                            Toggle(
                                user.displayName,
                                isOn: isSelected
                            )
                            .disabled(rootIsNsfwAndUserIsBlocked(user))
                        }
                    }
                }
                if let error { Section { Text(error).foregroundStyle(PrismediaColor.destructive) } }
            }
            .disabled(isWorking)
            .prismediaScreenBackground()
            .navigationTitle(target.root == nil ? "Add Library" : "Edit Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    PrismediaToolbarActionButton("Cancel", systemImage: "xmark") { dismiss() }
                        .disabled(isWorking)
                }
                ToolbarItem(placement: .confirmationAction) {
                    PrismediaToolbarActionButton("Save", systemImage: "checkmark") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isWorking)
                }
            }
        }
        .interactiveDismissDisabled(isWorking)
        .sheet(isPresented: $showsFolderPicker) {
            AdministrativeLibraryFolderPicker(initialPath: path, service: service) { path = $0 }
        }
    }

    private var isValid: Bool {
        !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && [scanVideos, scanImages, scanAudio, scanBooks].contains(true)
    }

    private func rootIsNsfwAndUserIsBlocked(_ user: UserAccount) -> Bool { isNsfw && !user.allowNsfw }

    private func save() async {
        guard !isWorking else { return }
        guard isValid else {
            error = "Choose a path and at least one media type."
            return
        }
        isWorking = true
        defer { isWorking = false }
        let mutation = AdministrativeLibraryRootMutation(
            path: path.trimmingCharacters(in: .whitespacesAndNewlines),
            label: label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil : label.trimmingCharacters(in: .whitespacesAndNewlines),
            enabled: enabled, recursive: recursive, scanVideos: scanVideos, scanImages: scanImages,
            scanAudio: scanAudio, scanBooks: scanBooks, isNsfw: isNsfw, autoIdentify: autoIdentify,
            grantUserIDs: target.root == nil && isAdministrator ? Array(selectedUserIDs) : nil
        )
        do {
            let saved =
                if let root = target.root {
                    try await service.update(id: root.id, mutation: mutation)
                } else {
                    try await service.create(mutation)
                }
            if target.root != nil && isAdministrator {
                try await service.replaceAccess(id: saved.id, userIDs: Array(selectedUserIDs))
            }
            onSaved(saved)
            dismiss()
        } catch let caught { error = caught.localizedDescription }
    }
}

#if DEBUG
    #Preview("Library Editor") {
        AdministrativeLibraryRootEditor(
            target: AdministrativeLibraryEditorTarget(),
            availableUsers: [],
            allowsNsfw: true,
            isAdministrator: true,
            service: Step3AdministrationPreviewService(),
            onSaved: { _ in }
        )
    }
#endif
