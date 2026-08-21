import SwiftUI

struct BookChapterMappingEditor: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @State private var draftByTrackID: [UUID: String]
    @State private var sourceSignature: String
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
        // Drafts hold only the user's manual rows: echoing the server-derived automatic layer
        // back through a save would promote it to manual and freeze it against future rescans.
        let manual = presentation.manualMappings
        let draft = Dictionary(
            uniqueKeysWithValues: manual.map { ($0.audioTrackID, $0.readableChapterKey) }
        )
        _draftByTrackID = State(initialValue: draft)
        _sourceSignature = State(initialValue: Self.signature(manual))
        _firstChapterKey = State(initialValue: Self.initialFirstChapterKey(presentation: presentation))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.extraLarge) {
            header
            firstChapterControl
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
                Text("Map files to readable chapters")
                    .font(.title3.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Choose where the first audiobook file begins, then Prismedia fills the remaining files in order. You can override any file below before saving."
                )
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
            }

            Spacer(minLength: PrismediaSpacing.medium)

            VStack(spacing: PrismediaSpacing.extraSmall) {
                Text(draftByTrackID.count, format: .number)
                    .font(.title3.monospacedDigit().bold())
                Text("mapped")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .padding(PrismediaSpacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(draftByTrackID.count) explicit mappings")
        }
    }

    private var firstChapterControl: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            if let firstTrack = presentation.orderedAudioTracks.first {
                Label {
                    VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        Text("First audiobook file")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textMuted)
                        Text(firstTrack.title)
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
                "Mark first chapter",
                systemImage: "arrow.down.to.line",
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent
            ) {
                markFirstChapter()
            }
            .disabled(isSaving || firstChapterKey == nil || presentation.orderedAudioTracks.isEmpty)
        }
        .padding(PrismediaSpacing.large)
        .prismediaPanel()
    }

    private var mappingList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(presentation.orderedAudioTracks.enumerated()), id: \.element.id) { index, track in
                BookChapterMappingEditorRow(
                    number: index + 1,
                    track: track,
                    chapters: presentation.orderedReadableChapters,
                    automaticChapterTitle: presentation.automaticChapterTitle(for: track.id),
                    isDisabled: isSaving,
                    selection: selectionBinding(for: track.id)
                )

                if track.id != presentation.orderedAudioTracks.last?.id {
                    Divider()
                        .overlay(PrismediaColor.borderSubtle)
                        .padding(.leading, PrismediaSpacing.large)
                }
            }
        }
        .prismediaPanel()
        .accessibilityLabel("Audiobook file chapter overrides")
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
            draftByTrackID = [:]
            didSave = false
            actionErrorMessage = nil
        }
        .disabled(isSaving || draftByTrackID.isEmpty)

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

    private var explicitMappings: [BookChapterAudioMapping] {
        presentation.orderedAudioTracks.compactMap { track in
            draftByTrackID[track.id].map {
                BookChapterAudioMapping(readableChapterKey: $0, audioTrackID: track.id)
            }
        }
    }

    private var isDirty: Bool {
        Self.signature(explicitMappings) != sourceSignature
    }

    private func selectionBinding(for trackID: UUID) -> Binding<String?> {
        Binding(
            get: { draftByTrackID[trackID] },
            set: { chapterKey in
                didSave = false
                actionErrorMessage = nil
                guard let chapterKey else {
                    draftByTrackID.removeValue(forKey: trackID)
                    return
                }
                if let duplicateTrackID = draftByTrackID.first(where: {
                    $0.key != trackID && $0.value == chapterKey
                })?.key {
                    draftByTrackID.removeValue(forKey: duplicateTrackID)
                }
                draftByTrackID[trackID] = chapterKey
            }
        )
    }

    private func markFirstChapter() {
        guard let firstChapterKey else { return }
        let mappings = BookChapterMappingBuilder().sequentialMappings(
            readableChapters: presentation.readableChapters,
            audioTracks: presentation.audioTracks,
            firstReadableChapterKey: firstChapterKey
        )
        draftByTrackID = Dictionary(
            uniqueKeysWithValues: mappings.map { ($0.audioTrackID, $0.readableChapterKey) }
        )
        didSave = false
        actionErrorMessage = nil
    }

    private func save() {
        guard isDirty, !isSaving else { return }
        isSaving = true
        actionErrorMessage = nil
        didSave = false
        Task { @MainActor in
            defer { isSaving = false }
            do {
                // The response is the merged map (manual plus refreshed automatic rows); only
                // the manual subset belongs back in the draft.
                let persistedManual = try await onSave(explicitMappings).filter { !$0.isAutomatic }
                draftByTrackID = Dictionary(
                    uniqueKeysWithValues: persistedManual.map { ($0.audioTrackID, $0.readableChapterKey) }
                )
                sourceSignature = Self.signature(persistedManual)
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
        let firstTrackID = presentation.orderedAudioTracks.first?.id
        if let mappedKey = presentation.manualMappings
            .first(where: { $0.audioTrackID == firstTrackID })?.readableChapterKey,
            presentation.readableChapters.contains(where: { $0.id == mappedKey })
        {
            return mappedKey
        }
        return presentation.orderedReadableChapters.first?.id
    }

    private static func signature(_ mappings: [BookChapterAudioMapping]) -> String {
        mappings
            .sorted {
                ($0.audioTrackID.uuidString, $0.readableChapterKey)
                    < ($1.audioTrackID.uuidString, $1.readableChapterKey)
            }
            .map { "\($0.audioTrackID.uuidString):\($0.readableChapterKey)" }
            .joined(separator: "|")
    }
}
