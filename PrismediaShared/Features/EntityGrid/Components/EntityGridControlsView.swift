import SwiftUI

struct EntityGridControlsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntityGridControls

    let catalog: EntityGridControlCatalog
    let onApply: (EntityGridControls) -> Void

    init(
        controls: EntityGridControls,
        catalog: EntityGridControlCatalog,
        onApply: @escaping (EntityGridControls) -> Void
    ) {
        _draft = State(initialValue: controls)
        self.catalog = catalog
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Library") {
                    Toggle("Favorites only", isOn: $draft.filters.favoriteOnly)
                    Picker("Organization", selection: $draft.filters.organization) {
                        Text("Any").tag(EntityGridOrganizationFilter.any)
                        Text("Organized").tag(EntityGridOrganizationFilter.organized)
                        Text("Not organized").tag(EntityGridOrganizationFilter.unorganized)
                    }
                }

                Section("Availability") {
                    Picker("Availability", selection: availabilitySelection) {
                        ForEach(Self.availabilityOptions) { option in
                            Text(option.label).tag(option.id)
                        }
                    }
                }

                if catalog.supportsEngagementFilters {
                    Section(catalog.usesReadingLabels ? "Reading" : "Playback") {
                        Picker("Status", selection: $draft.filters.engagement) {
                            Text("Any").tag(EntityGridEngagementFilter.any)
                            Text(catalog.usesReadingLabels ? "Read" : "Watched").tag(EntityGridEngagementFilter.watched)
                            Text(catalog.usesReadingLabels ? "Unread" : "Unwatched").tag(
                                EntityGridEngagementFilter.unwatched)
                            Text(catalog.usesReadingLabels ? "Reading" : "In progress").tag(
                                EntityGridEngagementFilter.inProgress)
                        }
                    }
                }

                Section("Rating") {
                    Picker("Rating", selection: ratingSelection) {
                        Text("Any").tag("any")
                        Text("Unrated").tag("unrated")
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating) stars or more").tag("minimum:\(rating)")
                        }
                    }
                    Picker("Maximum rating", selection: maximumRatingSelection) {
                        Text("Any").tag(0)
                        ForEach(1...5, id: \.self) { rating in
                            Text("\(rating) stars or less").tag(rating)
                        }
                    }
                    .disabled(draft.filters.rating == .unrated)
                }

                if catalog.supportsTaxonomyFilters {
                    Section("References") {
                        Picker("References", selection: $draft.filters.taxonomy) {
                            Text("Any").tag(EntityGridTaxonomyFilter.any)
                            Text("Has references").tag(EntityGridTaxonomyFilter.referenced)
                            Text("No references").tag(EntityGridTaxonomyFilter.orphaned)
                        }
                    }
                }

                if catalog.supportsBookFilters {
                    bookFilters
                }
            }
            .navigationTitle("Filters")
            .prismediaInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: resetToolbarPlacement) {
                    Button("Reset") { draft.filters = EntityGridFilters() }
                        .disabled(draft.filters.activeCount == 0)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .accessibilityIdentifier("entity.grid.filters")
    }

    private var resetToolbarPlacement: ToolbarItemPlacement {
        #if os(tvOS)
            .automatic
        #else
            .secondaryAction
        #endif
    }

    private var bookFilters: some View {
        Group {
            Section("Book Type") {
                ForEach(Self.bookTypes) { option in
                    Toggle(option.label, isOn: setBinding(option.id, in: \EntityGridFilters.bookTypes))
                }
            }
            Section("Book Format") {
                ForEach(Self.bookFormats) { option in
                    Toggle(option.label, isOn: setBinding(option.id, in: \EntityGridFilters.bookFormats))
                }
            }
        }
    }

    private var availabilitySelection: Binding<String> {
        Binding {
            if let status = draft.filters.acquisitionStatus { return "status:\(status.rawValue)" }
            return draft.filters.availability.rawValue
        } set: { selection in
            draft.filters.acquisitionStatus = nil
            draft.filters.availability = .any
            if selection == "onDisk" { draft.filters.availability = .onDisk }
            if selection == "wanted" { draft.filters.availability = .wanted }
            if selection.hasPrefix("status:") {
                draft.filters.acquisitionStatus = AcquisitionStatus(
                    rawValue: String(selection.dropFirst("status:".count))
                )
            }
        }
    }

    private var ratingSelection: Binding<String> {
        Binding {
            switch draft.filters.rating {
            case .any: "any"
            case .unrated: "unrated"
            case .atLeast(let value): "minimum:\(value)"
            }
        } set: { selection in
            if selection == "unrated" {
                draft.filters.rating = .unrated
                draft.filters.maximumRating = nil
            } else if let value = Int(selection.replacingOccurrences(of: "minimum:", with: "")) {
                draft.filters.rating = .atLeast(value)
            } else {
                draft.filters.rating = .any
            }
        }
    }

    private var maximumRatingSelection: Binding<Int> {
        Binding {
            draft.filters.maximumRating ?? 0
        } set: { value in
            draft.filters.maximumRating = value == 0 ? nil : value
            if value > 0, draft.filters.rating == .unrated {
                draft.filters.rating = .any
            }
        }
    }

    private func setBinding(
        _ value: String,
        in keyPath: WritableKeyPath<EntityGridFilters, Set<String>>
    ) -> Binding<Bool> {
        Binding {
            draft.filters[keyPath: keyPath].contains(value)
        } set: { enabled in
            if enabled {
                draft.filters[keyPath: keyPath].insert(value)
            } else {
                draft.filters[keyPath: keyPath].remove(value)
            }
        }
    }

    private static let availabilityOptions = [
        Option(id: "any", label: "Any"),
        Option(id: "onDisk", label: "On disk"),
        Option(id: "wanted", label: "Wanted"),
        Option(id: "status:pending", label: "Pending"),
        Option(id: "status:searching", label: "Searching"),
        Option(id: "status:awaiting-selection", label: "Review"),
        Option(id: "status:queued", label: "Queued"),
        Option(id: "status:downloading", label: "Downloading"),
        Option(id: "status:downloaded", label: "Downloaded"),
        Option(id: "status:importing", label: "Importing"),
        Option(id: "status:imported", label: "Imported"),
        Option(id: "status:stopping", label: "Cleaning up"),
        Option(id: "status:failed", label: "Failed"),
        Option(id: "status:cancelled", label: "Cancelled"),
        Option(id: "status:manual-import-required", label: "Needs attention"),
    ]

    private static let bookTypes = [
        Option(id: "book", label: "Book"),
        Option(id: "comic", label: "Comic"),
        Option(id: "manga", label: "Manga"),
        Option(id: "novel", label: "Novel"),
    ]

    private static let bookFormats = [
        Option(id: "image-archive", label: "Comic Archive"),
        Option(id: "epub", label: "EPUB"),
        Option(id: "pdf", label: "PDF"),
    ]
}

#if DEBUG
    #Preview("Entity Grid Filters") {
        EntityGridControlsView(
            controls: EntityGridControls(baselineQuery: EntityListQuery(kind: .book)),
            catalog: EntityGridControlCatalog(query: EntityListQuery(kind: .book)),
            onApply: { _ in }
        )
    }
#endif
