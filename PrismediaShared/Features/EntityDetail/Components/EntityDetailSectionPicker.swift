import SwiftUI

struct EntityDetailSectionPicker: View {
    let sections: [EntityDetailSection]
    @Binding var selection: EntityDetailSectionID
    let horizontalPadding: CGFloat

    var body: some View {
        Picker("Detail section", selection: $selection) {
            ForEach(sections) { section in
                Label(sectionTitle(section), systemImage: section.systemImage)
                    .tag(section.id)
                    .accessibilityIdentifier("entity-detail.tab.\(section.id.rawValue)")
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, horizontalPadding)
        .prismediaFocusSection()
        .accessibilityIdentifier("entity-detail.section-picker")
        .onAppear { selectAvailableSection() }
        .onChange(of: sections.map(\.id)) { selectAvailableSection() }
    }

    private func sectionTitle(_ section: EntityDetailSection) -> String {
        guard let count = section.count else { return section.title }
        return "\(section.title) \(count)"
    }

    private func selectAvailableSection() {
        guard !sections.contains(where: { $0.id == selection }) else { return }
        selection = sections.first?.id ?? .details
    }
}

#if DEBUG
    #Preview("Entity Detail Sections") {
        @Previewable @State var selection = EntityDetailSectionID.details

        EntityDetailSectionPicker(
            sections: [
                .init(id: .details, title: "Details", systemImage: "text.alignleft", count: nil),
                .init(id: .metadata, title: "Metadata", systemImage: "info.circle", count: nil),
                .init(id: .markers, title: "Markers", systemImage: "bookmark", count: 4),
            ],
            selection: $selection,
            horizontalPadding: PrismediaSpacing.extraLarge
        )
        .padding(.vertical)
    }
#endif
