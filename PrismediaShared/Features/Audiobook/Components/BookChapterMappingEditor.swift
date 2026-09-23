import SwiftUI

struct BookChapterMappingEditor: View {
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @State private var draftByChapterID: [String: String]
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
            uniqueKeysWithValues: manual.map { (Self.identity(for: $0), $0.readableChapterKey) }
        )
        _draftByChapterID = State(initialValue: draft)
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
                Text("Map audio chapters to readable chapters")
                    .font(.title3.bold())
                    .foregroundStyle(PrismediaColor.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    "Choose where the first audio chapter begins, then Prismedia fills the remaining chapters in order. You can override any chapter below before saving."
                )
                .font(.subheadline)
                .foregroundStyle(PrismediaColor.textSecondary)
            }

            Spacer(minLength: PrismediaSpacing.medium)

            VStack(spacing: PrismediaSpacing.extraSmall) {
                Text(presentation.alignedCount, format: .number)
                    .font(.title3.monospacedDigit().bold())
                Text("of \(presentation.orderedAudioChapters.count) aligned")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                Text("\(presentation.automaticCount) automatic · \(draftByChapterID.count) explicit")
                    .font(.caption2)
                    .foregroundStyle(PrismediaColor.textMuted)
            }
            .padding(PrismediaSpacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(presentation.alignedCount) of \(presentation.orderedAudioChapters.count) audio chapters aligned, \(presentation.automaticCount) automatic, \(draftByChapterID.count) explicit")
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
                "Mark first chapter",
                systemImage: "arrow.down.to.line",
                variant: .prominent,
                form: .fill,
                primaryTint: artworkPrimaryAccent
            ) {
                markFirstChapter()
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
                    isDisabled: isSaving,
                    selection: selectionBinding(for: chapter.identity)
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
            draftByChapterID = [:]
            didSave = false
            actionErrorMessage = nil
        }
        .disabled(isSaving || draftByChapterID.isEmpty)

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
        presentation.orderedAudioChapters.compactMap { chapter in
            draftByChapterID[chapter.identity].map {
                BookChapterAudioMapping(
                    readableChapterKey: $0,
                    audioTrackID: chapter.audioTrackID,
                    audioMarkerID: chapter.audioMarkerID
                )
            }
        }
    }

    private var isDirty: Bool {
        Self.signature(explicitMappings) != sourceSignature
    }

    private func selectionBinding(for chapterID: String) -> Binding<String?> {
        Binding(
            get: { draftByChapterID[chapterID] },
            set: { chapterKey in
                didSave = false
                actionErrorMessage = nil
                guard let chapterKey else {
                    draftByChapterID.removeValue(forKey: chapterID)
                    return
                }
                if let duplicateChapterID = draftByChapterID.first(where: {
                    $0.key != chapterID && $0.value == chapterKey
                })?.key {
                    draftByChapterID.removeValue(forKey: duplicateChapterID)
                }
                draftByChapterID[chapterID] = chapterKey
            }
        )
    }

    private func markFirstChapter() {
        guard let firstChapterKey else { return }
        let mappings = BookChapterMappingBuilder().sequentialMappings(
            readableChapters: presentation.readableChapters,
            audioTracks: presentation.audioTracks,
            audioChapters: presentation.audioChapters,
            firstReadableChapterKey: firstChapterKey
        )
        draftByChapterID = Dictionary(
            uniqueKeysWithValues: mappings.map { (Self.identity(for: $0), $0.readableChapterKey) }
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
                draftByChapterID = Dictionary(
                    uniqueKeysWithValues: persistedManual.map { (Self.identity(for: $0), $0.readableChapterKey) }
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

    private static func signature(_ mappings: [BookChapterAudioMapping]) -> String {
        mappings
            .sorted {
                ($0.audioTrackID.uuidString, $0.audioMarkerID?.uuidString ?? "", $0.readableChapterKey)
                    < ($1.audioTrackID.uuidString, $1.audioMarkerID?.uuidString ?? "", $1.readableChapterKey)
            }
            .map { "\(Self.identity(for: $0)):\($0.readableChapterKey)" }
            .joined(separator: "|")
    }

    private static func identity(for mapping: BookChapterAudioMapping) -> String {
        "\(mapping.audioTrackID.uuidString):\(mapping.audioMarkerID?.uuidString ?? "whole")"
    }
}
