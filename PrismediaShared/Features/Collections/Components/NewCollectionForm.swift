#if os(iOS) || os(macOS)
    import SwiftUI

    /// Title, description, and visibility fields for a new manual Collection.
    ///
    /// The form dismisses itself once `onCreate` succeeds, which closes a hosting sheet or pops the form
    /// when it was pushed inside one. A thrown error stays on the form so the user can correct and retry.
    struct NewCollectionForm: View {
        // MARK: - Variables

        @Environment(\.dismiss) private var dismiss
        @Environment(PrismediaAppEnvironment.self) private var environment
        @FocusState private var titleIsFocused: Bool
        @State private var draft: CollectionDraft
        @State private var errorMessage: String?
        @State private var isCreating = false

        private let showsCancelAction: Bool
        private let onCreate: (CollectionDraft) async throws -> Void

        // MARK: - Initializers

        /// - Parameters:
        ///   - initialTitle: Title to start from, such as the text a picker was filtered by.
        ///   - showsCancelAction: Whether to offer Cancel; a pushed form relies on the back button instead.
        ///   - onCreate: Creates the Collection. The form dismisses itself when it returns.
        init(
            initialTitle: String = "",
            showsCancelAction: Bool = false,
            onCreate: @escaping (CollectionDraft) async throws -> Void
        ) {
            _draft = State(initialValue: CollectionDraft(title: initialTitle))
            self.showsCancelAction = showsCancelAction
            self.onCreate = onCreate
        }

        var body: some View {
            Form {
                Section {
                    TextField("Title", text: $draft.title)
                        .focused($titleIsFocused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .accessibilityIdentifier("new-collection.title")

                    TextField("Description", text: $draft.description, axis: .vertical)
                        .lineLimit(2...6)
                        .accessibilityIdentifier("new-collection.description")
                }

                Section {
                    Toggle("Shared", isOn: $draft.isShared)
                        .accessibilityIdentifier("new-collection.shared")

                    if environment.allowsNsfwContent {
                        Toggle("NSFW", isOn: $draft.isNsfw)
                            .accessibilityIdentifier("new-collection.nsfw")
                    }
                } footer: {
                    Text(draft.isShared ? "Visible to every signed-in user." : "Visible only to you.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PrismediaColor.destructive)
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(isCreating)
            .prismediaScreenBackground()
            .navigationTitle("New Collection")
            .prismediaInlineNavigationTitle()
            .navigationBarBackButtonHidden(isCreating)
            .interactiveDismissDisabled(isCreating)
            .toolbar {
                if showsCancelAction {
                    ToolbarItem(placement: .cancellationAction) {
                        PrismediaToolbarActionButton("Cancel", systemImage: "xmark") {
                            dismiss()
                        }
                        .disabled(isCreating)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if isCreating {
                        ProgressView()
                    } else {
                        PrismediaToolbarActionButton("Create", systemImage: "checkmark", action: submit)
                            .disabled(!draft.canSubmit)
                            .accessibilityIdentifier("new-collection.create")
                    }
                }
            }
            .onAppear { titleIsFocused = true }
            .accessibilityIdentifier("new-collection.form")
        }

        // MARK: - Actions - Creation

        private func submit() {
            guard draft.canSubmit, !isCreating else { return }
            Task { await create() }
        }

        private func create() async {
            isCreating = true
            errorMessage = nil
            defer { isCreating = false }
            do {
                try await onCreate(draft)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
        #Preview("New Collection · Empty") {
            PreviewShell(signedIn: true) {
                NavigationStack {
                    NewCollectionForm(showsCancelAction: true) { _ in }
                }
            }
        }

        #Preview("New Collection · Prefilled") {
            PreviewShell(signedIn: true) {
                NavigationStack {
                    NewCollectionForm(initialTitle: "Weekend Favorites") { _ in }
                }
            }
        }

        #Preview("New Collection · Error") {
            PreviewShell(signedIn: true) {
                NavigationStack {
                    NewCollectionForm(initialTitle: "Weekend Favorites") { _ in
                        throw PrismediaAPIError.httpStatus(
                            400,
                            APIProblem(
                                code: PrismediaContractCodes.ProblemCode.invalidCollection,
                                message: "Collection title is required."
                            )
                        )
                    }
                }
            }
        }

        #Preview("New Collection · Accessibility Size") {
            PreviewShell(signedIn: true) {
                NavigationStack {
                    NewCollectionForm(initialTitle: "Weekend Favorites", showsCancelAction: true) { _ in }
                }
            }
            .dynamicTypeSize(.accessibility3)
        }
    #endif
#endif
