import SwiftUI

/// Lazy page-resource preview grid for one comic installment. The cards are reader resources,
/// not Entity links, and selecting one opens the shared manifest reader at that ordinal.
struct ComicPageThumbnailGrid: View {
    let pages: [BookReaderPage]
    let horizontalPadding: CGFloat
    let onSelect: (Int) -> Void

    @State private var cache: BookReaderPageCache

    init(
        pages: [BookReaderPage],
        service: any BookReaderServicing,
        horizontalPadding: CGFloat,
        onSelect: @escaping (Int) -> Void
    ) {
        self.pages = pages
        self.horizontalPadding = horizontalPadding
        self.onSelect = onSelect
        _cache = State(initialValue: BookReaderPageCache(service: service, maximumPixelSize: 768))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pages")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(pages.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 112, maximum: 180), spacing: PrismediaSpacing.medium)],
                alignment: .leading,
                spacing: PrismediaSpacing.medium
            ) {
                ForEach(pages.indices, id: \.self) { index in
                    let page = pages[index]
                    Button {
                        onSelect(index)
                    } label: {
                        AuthenticatedComicPage(page: page, cache: cache, fit: false)
                            .aspectRatio(2 / 3, contentMode: .fit)
                            .overlay(alignment: .bottomLeading) {
                                Text("\(index + 1)")
                                    .font(.caption2.monospacedDigit().weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 4)
                                    .background(.black.opacity(0.72), in: .rect(cornerRadius: PrismediaRadius.badge))
                                    .padding(6)
                            }
                            .clipShape(.rect(cornerRadius: PrismediaRadius.compact))
                            .overlay {
                                RoundedRectangle(cornerRadius: PrismediaRadius.compact, style: .continuous)
                                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open page \(index + 1)")
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
        .accessibilityIdentifier("entity-detail.comic-pages")
    }
}
