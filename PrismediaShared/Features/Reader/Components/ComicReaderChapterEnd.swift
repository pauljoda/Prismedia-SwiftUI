import SwiftUI

struct ComicReaderChapterEnd: View {
    let nextChapterTitle: String?
    let isAdvancingChapter: Bool
    let action: () -> Void

    var body: some View {
        VStack(spacing: PrismediaSpacing.extraLarge) {
            Text(nextChapterTitle == nil ? "NO NEXT CHAPTER" : "NEXT CHAPTER")
                .font(.caption.monospaced().weight(.bold))
                .tracking(1.6)
                .foregroundStyle(PrismediaColor.accent)
            Text(nextChapterTitle ?? "You’ve reached the end")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            PrismediaButton(
                nextChapterTitle == nil ? "Close Reader" : "Continue Reading",
                systemImage: "chevron.right",
                variant: .prominent,
                form: .fill,
                surface: .embedded,
                isLoading: isAdvancingChapter,
                action: action
            )
            .disabled(isAdvancingChapter)
        }
        .padding(PrismediaSpacing.section)
        .frame(maxWidth: 620, maxHeight: .infinity)
        .background(
            PrismediaColor.elevatedContentBackground.opacity(0.92), in: .rect(cornerRadius: PrismediaRadius.control)
        )
        .padding(PrismediaSpacing.extraLarge)
    }
}
#if DEBUG
    #Preview("Comic Reader Chapter End") {
        ComicReaderChapterEnd(
            nextChapterTitle: "Chapter Two: Beyond the Signal",
            isAdvancingChapter: false,
            action: {}
        )
        .frame(width: 480, height: 500)
    }
#endif
