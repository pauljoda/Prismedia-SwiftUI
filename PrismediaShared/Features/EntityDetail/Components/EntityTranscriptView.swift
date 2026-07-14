import SwiftUI

struct EntityTranscriptView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.artworkPrimaryAccent) private var artworkPrimaryAccent
    @Environment(\.artworkSecondaryText) private var artworkSecondaryText
    @State private var state = EntityTranscriptState()
    @State private var retryRevision = 0
    let videoID: UUID?
    let subtitles: [EntitySubtitle]
    let sourceLoader: (any EntityTranscriptSourceLoading)?
    let currentTime: Double?
    let onSeek: ((Double) -> Void)?

    init(
        videoID: UUID?,
        subtitles: [EntitySubtitle],
        sourceLoader: (any EntityTranscriptSourceLoading)?,
        currentTime: Double? = nil,
        onSeek: ((Double) -> Void)? = nil
    ) {
        self.videoID = videoID
        self.subtitles = subtitles
        self.sourceLoader = sourceLoader
        self.currentTime = currentTime
        self.onSeek = onSeek
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            if subtitles.isEmpty {
                unavailableContent(
                    title: "No Transcript",
                    message: "This video does not have any subtitle tracks.",
                    systemImage: "captions.bubble"
                )
            } else if videoID == nil || sourceLoader == nil {
                unavailableContent(
                    title: "Transcript Unavailable",
                    message: "The transcript source is not available for this item.",
                    systemImage: "captions.bubble"
                )
            } else {
                controls
                phaseContent
            }
        }
        .task(id: loadTaskID) {
            await loadSelectedTrack()
        }
        .accessibilityIdentifier("entity-detail.transcript")
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            if subtitles.count > 1 {
                Picker("Subtitle Track", selection: trackSelection) {
                    ForEach(subtitles, id: \.id) { subtitle in
                        Text(trackLabel(subtitle))
                            .tag(subtitle.id)
                    }
                }
                .pickerStyle(.menu)
            }

            #if os(tvOS)
                TextField("Search Transcript", text: searchText)
                    .prismediaTextInputStyle()
                    .accessibilityHint("Filters cues using all entered words")
            #else
                TextField("Search Transcript", text: searchText)
                    .prismediaTextInputStyle()
                    .accessibilityHint("Filters cues using all entered words")
            #endif
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch state.phase {
        case .idle, .loading:
            HStack(spacing: PrismediaSpacing.medium) {
                ProgressView()
                Text("Loading transcript…")
                    .foregroundStyle(artworkSecondaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        case .failure(let message):
            ContentUnavailableView {
                Label("Couldn’t Load Transcript", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                PrismediaButton("Try Again", variant: .prominent) {
                    retryRevision += 1
                }
            }
            .frame(maxWidth: .infinity, minHeight: 180)
        case .content:
            cueList
        }
    }

    @ViewBuilder
    private var cueList: some View {
        if state.cues.isEmpty {
            unavailableContent(
                title: "Empty Transcript",
                message: "This subtitle track does not contain any cues.",
                systemImage: "text.badge.minus"
            )
        } else if state.filteredCues.isEmpty {
            unavailableContent(
                title: "No Results",
                message: "Try a different transcript search.",
                systemImage: "magnifyingglass"
            )
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                        ForEach(state.filteredCues) { cue in
                            cueSurface(cue)
                                .id(cue.id)
                        }
                    }
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                }
                .frame(minHeight: 180, maxHeight: 420)
                .onChange(of: activeCueID) { _, current in
                    guard state.searchText.isEmpty, let current else { return }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                        proxy.scrollTo(current, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cueSurface(_ cue: EntityTranscriptCue) -> some View {
        if let onSeek {
            Button {
                onSeek(cue.startTime)
            } label: {
                cueContent(cue)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Seeks the active video to this cue")
        } else {
            cueContent(cue)
                .accessibilityHint("Start this video on the current page to enable seeking")
        }
    }

    private func cueContent(_ cue: EntityTranscriptCue) -> some View {
        let isActive = cue.id == activeCueID
        return HStack(alignment: .firstTextBaseline, spacing: PrismediaSpacing.medium) {
            Text(clockTime(cue.startTime))
                .font(.caption.monospacedDigit())
                .foregroundStyle(isActive ? artworkPrimaryAccent : artworkSecondaryText)
                .frame(minWidth: 46, alignment: .leading)

            Text(cue.text)
                .font(.body)
                .foregroundStyle(PrismediaColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isActive {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundStyle(artworkPrimaryAccent)
                    .accessibilityLabel("Current cue")
            }
        }
        .padding(.horizontal, PrismediaSpacing.medium)
        .padding(.vertical, PrismediaSpacing.small)
        .background(
            isActive
                ? artworkPrimaryAccent.opacity(0.14)
                : PrismediaColor.elevatedContentBackground.opacity(0.5)
        )
        .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }

    private var trackSelection: Binding<String> {
        Binding(
            get: { selectedTrackID ?? "" },
            set: { state.selectTrack($0) }
        )
    }

    private var searchText: Binding<String> {
        Binding(
            get: { state.searchText },
            set: { state.searchText = $0 }
        )
    }

    private var selectedTrackID: String? {
        if let selectedTrackID = state.selectedTrackID,
            subtitles.contains(where: { $0.id == selectedTrackID })
        {
            return selectedTrackID
        }
        return subtitles.first(where: \.isDefault)?.id ?? subtitles.first?.id
    }

    private var activeCueID: EntityTranscriptCue.ID? {
        state.activeCueID(at: currentTime)
    }

    private var loadTaskID: String {
        "\(videoID?.uuidString ?? "none"):\(selectedTrackID ?? "none"):\(retryRevision)"
    }

    private func loadSelectedTrack() async {
        guard let videoID,
            let selectedTrackID,
            let sourceLoader
        else {
            state.reset()
            return
        }
        let request = state.beginLoad(videoID: videoID, trackID: selectedTrackID)
        let outcome = await EntityTranscriptService(sourceLoader: sourceLoader).load(
            videoID: videoID,
            trackID: selectedTrackID
        )
        state.finishLoad(outcome, request: request)
    }

    private func trackLabel(_ subtitle: EntitySubtitle) -> String {
        subtitle.label ?? subtitle.language.uppercased()
    }

    private func unavailableContent(
        title: String,
        message: String,
        systemImage: String
    ) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(message)
        )
        .frame(maxWidth: .infinity, minHeight: 160)
    }

    private func clockTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        let remainingSeconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

#if DEBUG
    #Preview("Transcript") {
        EntityTranscriptView(
            videoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
            subtitles: [.transcriptPreview],
            sourceLoader: PreviewEntityTranscriptSourceLoader(),
            currentTime: 6,
            onSeek: { _ in }
        )
        .padding()
        .frame(width: 620)
    }

    #Preview("Transcript Empty") {
        EntityTranscriptView(
            videoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
            subtitles: [.transcriptPreview],
            sourceLoader: PreviewEntityTranscriptSourceLoader(data: Data("WEBVTT\n\n".utf8))
        )
        .padding()
        .frame(width: 620)
    }

    #Preview("Transcript Dark Accessibility") {
        EntityTranscriptView(
            videoID: UUID(uuidString: "11111111-1111-1111-1111-111111111111"),
            subtitles: [.transcriptPreview],
            sourceLoader: PreviewEntityTranscriptSourceLoader(),
            currentTime: 2
        )
        .padding()
        .frame(width: 720)
        .environment(\.colorScheme, .dark)
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
    }
    extension EntitySubtitle {
        fileprivate static var transcriptPreview: EntitySubtitle {
            EntitySubtitle(
                id: "english",
                language: "en",
                label: "English",
                format: "vtt",
                source: "sidecar",
                storagePath: "english.vtt",
                sourceFormat: "vtt",
                sourcePath: nil,
                isDefault: true
            )
        }
    }
#endif
