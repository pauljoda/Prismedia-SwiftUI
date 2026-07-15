import SwiftUI

struct EntityDetailEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntityDetailEditDraft
    @State private var selectedSection = EntityDetailEditSection.main
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let presentation: EntityDetailEditPresentation
    private let originalDraft: EntityDetailEditDraft
    private let service: EntityDetailEditService
    private let referenceSearchService: EntityDetailReferenceSearchService
    private let onSaved: @MainActor () async -> Void

    init(
        presentation: EntityDetailEditPresentation,
        service: EntityDetailEditService,
        referenceLoader: any EntityGridLoading,
        onSaved: @escaping @MainActor () async -> Void
    ) {
        let draft = EntityDetailEditDraft(detail: presentation.detail)
        self.presentation = presentation
        self.originalDraft = draft
        self.service = service
        self.referenceSearchService = EntityDetailReferenceSearchService(loader: referenceLoader)
        self.onSaved = onSaved
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Edit section", selection: $selectedSection) {
                        ForEach(EntityDetailEditSection.allCases) { section in
                            Text(section.title).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("entity-detail.edit.section-picker")
                }

                switch selectedSection {
                case .main:
                    mainForm
                case .metadata:
                    metadataForm
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(PrismediaColor.destructive)
                            .accessibilityIdentifier("entity-detail.edit.error")
                    }
                }
            }
            .navigationTitle("Edit Entity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!isDirty || isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isDirty || isSaving)
        .accessibilityIdentifier("entity-detail.edit.sheet")
    }

    @ViewBuilder
    private var mainForm: some View {
        Section("Identity") {
            TextField("Title", text: $draft.title)

            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text("Description")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
                #if os(tvOS)
                    TextField("Description", text: $draft.description)
                #else
                    TextEditor(text: $draft.description)
                        .frame(minHeight: 140)
                        .scrollContentBackground(.hidden)
                        .padding(PrismediaSpacing.small)
                        .background(
                            PrismediaColor.controlFill,
                            in: .rect(cornerRadius: PrismediaRadius.compact)
                        )
                #endif
            }
        }

        Section("User Metadata") {
            Picker("Rating", selection: $draft.rating) {
                Text("Unrated").tag(Int?.none)
                ForEach(1...5, id: \.self) { value in
                    Text("\(value) star\(value == 1 ? "" : "s")").tag(Int?.some(value))
                }
            }

            Toggle("Favorite", isOn: $draft.isFavorite)
            Toggle("NSFW", isOn: $draft.isNsfw)
            Toggle("Organized", isOn: $draft.isOrganized)
        }

        if EntityDetailEditPolicy.canEditTags(in: presentation.detail) {
            EntityDetailReferenceSelector(
                selection: $draft.tags,
                title: "Tags",
                kind: .tag,
                mode: .multiple,
                searchService: referenceSearchService
            )
        }

        if EntityDetailEditPolicy.canEditStudio(in: presentation.detail) {
            EntityDetailReferenceSelector(
                selection: studioSelection,
                title: "Studio",
                kind: .studio,
                mode: .single,
                searchService: referenceSearchService
            )
        }

        if EntityDetailEditPolicy.canEditCredits(in: presentation.detail) {
            EntityDetailCreditsEditor(
                credits: $draft.credits,
                defaultRole: EntityDetailEditPolicy.defaultCreditRole(in: presentation.detail),
                searchService: referenceSearchService
            )
        }
    }

    @ViewBuilder
    private var metadataForm: some View {
        EntityDetailStringListEditor(
            title: "Links",
            placeholder: "https://example.com",
            values: $draft.urls
        )

        EntityDetailKeyValueEditor(
            title: "External IDs",
            keyPlaceholder: "Provider",
            valuePlaceholder: "ID",
            valueUsesNumberKeyboard: false,
            values: $draft.externalIDs
        )

        EntityDetailKeyValueEditor(
            title: "Dates",
            keyPlaceholder: "Code",
            valuePlaceholder: "YYYY-MM-DD",
            valueUsesNumberKeyboard: false,
            values: $draft.dates
        )

        EntityDetailKeyValueEditor(
            title: "Stats",
            keyPlaceholder: "Code",
            valuePlaceholder: "Value",
            valueUsesNumberKeyboard: true,
            values: $draft.stats
        )

        EntityDetailKeyValueEditor(
            title: "Positions",
            keyPlaceholder: "Code",
            valuePlaceholder: "Value",
            valueUsesNumberKeyboard: true,
            values: $draft.positions
        )

        Section("Classification") {
            TextField("Classification", text: $draft.classification)
        }
    }

    private var isDirty: Bool {
        draft != originalDraft
    }

    private var studioSelection: Binding<[EntityDetailReferenceDraft]> {
        Binding(
            get: { draft.studio.map { [$0] } ?? [] },
            set: { draft.studio = $0.first }
        )
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil
        let outcome = await service.save(
            draft: draft,
            original: originalDraft,
            detail: presentation.detail
        )
        switch outcome {
        case .saved:
            await onSaved()
            dismiss()
        case .failed(let message, let savedPartialChanges):
            if savedPartialChanges { await onSaved() }
            errorMessage = message
        }
        isSaving = false
    }
}

#if DEBUG
    #Preview("Entity Detail Edit") {
        let detail = EntityDetailPreviewFixture.detail
        let mutator = PreviewEntityDetailEditMutator(detail: detail)

        PreviewShell {
            EntityDetailEditSheet(
                presentation: EntityDetailEditPresentation(detail: detail),
                service: EntityDetailEditService(
                    metadataMutator: mutator,
                    userMetadataMutator: mutator
                ),
                referenceLoader: StaticEntityGridLoader(
                    items: detail.relationships.flatMap(\.entities)
                ),
                onSaved: {}
            )
        }
    }
#endif
