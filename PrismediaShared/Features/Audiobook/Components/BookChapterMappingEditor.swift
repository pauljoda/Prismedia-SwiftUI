import SwiftUI

struct BookChapterMappingEditor: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @State private var draft: BookChapterMappingDraft
    @State private var sourceSignature: String
    /// An in-order fill waiting for review; nothing enters the draft until every pair has been seen.
    @State private var proposedFill: [BookChapterAudioMapping]?
    @State private var firstChapterKey: String?
    @State private var isSaving = false
    @State private var actionErrorMessage: String?
    @State private var didSave = false

    let presentation: BookChapterMappingEditorPresentation
    let onSave: @MainActor ([BookChapterAudioMapping]) async throws -> [BookChapterAudioMapping]

    init(
        presentation: BookChapterMappingEditorPresentation,
        onSave: @escaping @MainActor ([BookChapterAudioMapping]) async throws -> [BookChapterAudioMapping]
    ) {
        self.presentation = presentation
        self.onSave = onSave
        // Drafts hold only the person-confirmed rows (manual or ordered): the server-derived
        // automatic layer is server-owned and a save must never echo it back.
        let draft = BookChapterMappingDraft(persisted: presentation.manualMappings)
        _draft = State(initialValue: draft)
        let confirmed = draft.mappings(orderedBy: presentation.orderedAudioChapters)
        _sourceSignature = State(initialValue: BookChapterMappingDraft.signature(confirmed))
        _firstChapterKey = State(initialValue: Self.initialFirstChapterKey(presentation: presentation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
            header
            firstChapterControl
            if let proposedFill {
                BookChapterMappingFillReview(
                    proposal: proposedFill,
                    audioChapters: presentation.orderedAudioChapters,
                    readableChapters: presentation.readableChapters,
                    onDiscard: { self.proposedFill = nil },
                    onAccept: acceptFillInOrder
                )
            }
            mappingList
            footer
        }
        .accessibilityIdentifier("book-chapter-mapping.editor")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: PrismediaSpacing.large) {
            VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                Text("Audiobook alignment")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PrismediaColor.textMuted)
                    .textCase(.uppercase)
                Text("Map audio chapters to readable chapters")
                    .font(.title3.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Prismedia pairs chapters automatically only when their titles match exactly. Pick pairs yourself, or fill in order from a chapter and review every pair before saving."
                )
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
                if let separateExplanation = presentation.separateExplanation {
                    Label(separateExplanation, systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }

            Spacer(minLength: PrismediaSpacing.medium)

            VStack(spacing: PrismediaSpacing.extraSmall) {
                Text(presentation.alignedCount, format: .number)
                    .font(.title3.monospacedDigit().bold())
                Text("of \(presentation.orderedAudioChapters.count) aligned")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                Text("\(presentation.automaticCount) exact title · \(draft.count) confirmed")
                    .font(.caption2)
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .padding(PrismediaSpacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(presentation.alignedCount) of \(presentation.orderedAudioChapters.count) audio chapters aligned, \(presentation.automaticCount) by exact title, \(draft.count) confirmed")
        }
    }

    private var firstChapterControl: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            if let firstChapter = presentation.orderedAudioChapters.first {
                Label {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("First audio chapter")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                        Text(firstChapter.title)
                            .font(.headline)
                            .foregroundStyle(PrismediaColor.textPrimary)
                    }
                } icon: {
                    Image(systemName: "waveform")
                        .foregroundStyle(PrismediaColor.textSecondary)
                }
            }

            Picker("Starts at readable chapter", selection: $firstChapterKey) {
                ForEach(presentation.orderedReadableChapters) { chapter in
                    Text(chapter.title)
                        .tag(Optional(chapter.id))
                }
            }
            .pickerStyle(.menu)

            PrismediaButton(
                "Fill in order from here",
                systemImage: "arrow.down.to.line",
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent
            ) {
                proposeFillInOrder()
            }
            .disabled(isSaving || firstChapterKey == nil || presentation.orderedAudioChapters.isEmpty)
        }
        .padding(PrismediaSpacing.large)
        .prismediaPanel()
    }

    private var mappingList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(presentation.orderedAudioChapters.enumerated()), id: \.element.identity) { index, chapter in
                BookChapterMappingEditorRow(
                    number: index + 1,
                    audioChapter: chapter,
                    chapters: presentation.orderedReadableChapters,
                    automaticChapterTitle: presentation.automaticChapterTitle(for: chapter),
                    origin: draft.origin(for: chapter),
                    isDisabled: isSaving,
                    selection: selectionBinding(for: chapter)
                )

                if chapter.identity != presentation.orderedAudioChapters.last?.identity {
                    Divider()
                        .overlay(PrismediaColor.borderSubtle)
                        .padding(.leading, PrismediaSpacing.large)
                }
            }
        }
        .prismediaPanel()
        .accessibilityLabel("Audiobook chapter overrides")
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            if let message = actionErrorMessage ?? presentation.loadErrorMessage {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.destructive)
                    .accessibilityLabel("Chapter mapping error: \(message)")
            } else if didSave {
                Label("Chapter mapping saved", systemImage: "checkmark")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.success)
            } else {
                Text(isDirty ? "Unsaved mapping changes" : "Mappings are up to date")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: PrismediaSpacing.medium) {
                    actions
                }
                VStack(spacing: PrismediaSpacing.medium) {
                    actions
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        PrismediaButton(
            "Clear overrides",
            systemImage: "link.badge.minus",
            form: .fill
        ) {
            draft.clear()
            proposedFill = nil
            didSave = false
            actionErrorMessage = nil
        }
        .disabled(isSaving || draft.isEmpty)

        PrismediaButton(
            "Save mapping",
            systemImage: "checkmark",
            variant: .prominent,
            form: .fill,
            primaryTint: artworkPrimaryAccent,
            isLoading: isSaving,
            loadingTitle: "Saving"
        ) {
            save()
        }
        .disabled(isSaving || !isDirty)
    }

    /// The save request: each confirmed pair `manual` or `ordered`, never automatic.
    private var confirmedMappings: [BookChapterAudioMapping] {
        draft.mappings(orderedBy: presentation.orderedAudioChapters)
    }

    private var isDirty: Bool {
        BookChapterMappingDraft.signature(confirmedMappings) != sourceSignature
    }

    /// A hand pick; it replaces any in-order provenance the row had.
    private func selectionBinding(for chapter: BookAudioChapter) -> Binding<String?> {
        Binding(
            get: { draft.readableChapterKey(for: chapter) },
            set: { chapterKey in
                didSave = false
                actionErrorMessage = nil
                draft.pick(chapterKey, for: chapter)
            }
        )
    }

    /// Proposes pairs in playback order from the chosen chapter; they are reviewed before use.
    private func proposeFillInOrder() {
        guard let firstChapterKey else { return }
        proposedFill = BookChapterMappingBuilder().sequentialMappings(
            readableChapters: presentation.readableChapters,
            audioTracks: presentation.audioTracks,
            audioChapters: presentation.audioChapters,
            firstReadableChapterKey: firstChapterKey
        )
        didSave = false
        actionErrorMessage = nil
    }

    /// Uses the reviewed in-order pairs as the draft; each keeps its "filled in order" origin.
    private func acceptFillInOrder() {
        guard let proposedFill else { return }
        draft.accept(filledInOrder: proposedFill)
        self.proposedFill = nil
    }

    private func save() {
        guard isDirty, !isSaving else { return }
        isSaving = true
        actionErrorMessage = nil
        didSave = false
        Task { @MainActor in
            defer { isSaving = false }
            do {
                // The response is the merged map (confirmed plus refreshed automatic rows); only
                // the confirmed subset belongs back in the draft.
                let persisted = BookChapterMappingDraft(persisted: try await onSave(confirmedMappings))
                draft = persisted
                sourceSignature = BookChapterMappingDraft.signature(
                    persisted.mappings(orderedBy: presentation.orderedAudioChapters)
                )
                didSave = true
            } catch is CancellationError {
                return
            } catch {
                actionErrorMessage = error.localizedDescription
            }
        }
    }

    private static func initialFirstChapterKey(
        presentation: BookChapterMappingEditorPresentation
    ) -> String? {
        let firstChapter = presentation.orderedAudioChapters.first
        if let mappedKey = presentation.manualMappings
            .first(where: {
                $0.audioTrackID == firstChapter?.audioTrackID
                    && $0.audioMarkerID == firstChapter?.audioMarkerID
            })?.readableChapterKey,
            presentation.readableChapters.contains(where: { $0.id == mappedKey })
        {
            return mappedKey
        }
        return presentation.orderedReadableChapters.first?.id
    }
}
