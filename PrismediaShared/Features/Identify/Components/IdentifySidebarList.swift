import SwiftUI

#if os(iOS) || os(macOS)
    struct IdentifySidebarList: View {
        @Bindable var session: IdentifySession
        let usesNavigationLinks: Bool

        var body: some View {
            Group {
                if usesNavigationLinks {
                    List {
                        Section("Browse by Kind") {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: PrismediaSpacing.medium
                            ) {
                                ForEach(session.kindSummaries) { summary in
                                    Button {
                                        session.selectedKind = summary.kind
                                    } label: {
                                        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                                            Image(systemName: systemImage(for: summary.kind))
                                                .font(.title3)

                                            VStack(alignment: .leading, spacing: PrismediaSpacing.extraSmall) {
                                                Text(summary.kind.displayLabel)
                                                    .font(.headline)
                                                Text(summary.kind.rawValue)
                                                    .font(.caption2.monospaced())
                                                    .foregroundStyle(.secondary)
                                            }

                                            Divider()

                                            HStack {
                                                if summary.pendingCount > 0 {
                                                    Text("\(summary.pendingCount) queued")
                                                        .font(.caption)
                                                }
                                                Spacer(minLength: 0)
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 132, alignment: .leading)
                                        .contentShape(.rect)
                                    }
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.roundedRectangle(radius: PrismediaRadius.card))
                                    .accessibilityHint("Browse \(summary.kind.displayLabel.lowercased()) items")
                                }
                            }
                            .padding(.vertical, PrismediaSpacing.small)
                            .listRowBackground(Color.clear)
                        }

                        if !session.queue.isEmpty {
                            Section("Review Queue") {
                                NavigationLink {
                                    IdentifyQueueView(
                                        session: session,
                                        presentsReviewInNavigationStack: true
                                    )
                                } label: {
                                    queueLabel
                                }
                            }
                        }
                    }
                } else {
                    List(selection: destinationSelection) {
                        Section("Work") {
                            queueLabel
                                .tag("queue")
                        }

                        Section("Library") {
                            ForEach(session.kindSummaries) { summary in
                                kindLabel(summary)
                                    .tag(summary.kind.rawValue)
                            }
                        }
                    }
                }
            }
            .prismediaScreenBackground()
            .navigationTitle("Identify")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
        }

        private var destinationSelection: Binding<String?> {
            Binding(
                get: { session.selectedKind?.rawValue ?? "queue" },
                set: { selection in
                    guard let selection, selection != "queue" else {
                        session.selectedKind = nil
                        session.selectedItemID = nil
                        return
                    }
                    session.selectedKind = EntityKind(rawValue: selection)
                }
            )
        }

        private var queueLabel: some View {
            HStack {
                Label("Identify Queue", systemImage: "checklist")
                Spacer()
                Text(session.queue.count, format: .number)
                    .foregroundStyle(.secondary)
            }
        }

        private func kindLabel(_ summary: IdentifyKindSummary) -> some View {
            HStack {
                Label(summary.kind.displayLabel, systemImage: "square.grid.2x2")
                Spacer()
                if summary.pendingCount > 0 {
                    Text(summary.pendingCount, format: .number)
                        .foregroundStyle(.secondary)
                }
            }
        }

        private func systemImage(for kind: EntityKind) -> String {
            switch kind {
            case .movie, .video: "film"
            case .videoSeries, .videoSeason: "rectangle.stack"
            case .book, .bookVolume, .bookChapter: "book.closed"
            case .person, .bookAuthor, .musicArtist: "person.crop.circle"
            case .studio: "building.2"
            case .audio, .audioLibrary, .audioTrack: "music.note"
            default: "square.grid.2x2"
            }
        }
    }

    #if DEBUG
        #Preview("Identify Sidebar") {
            NavigationStack {
                IdentifySidebarList(
                    session: .init(
                        service: AdministrativePreviewService(),
                        browser: IdentifyPreviewEntityBrowser(),
                        initialQueue: [IdentifyPreviewFixtures.reviewItem],
                        initialProviders: [IdentifyPreviewFixtures.provider]
                    ),
                    usesNavigationLinks: true
                )
            }
        }
    #endif
#endif
