import SwiftUI

#if os(tvOS)

    struct TVHomeHero: View {
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(TVTabFocusCoordinator.self) private var tabFocusCoordinator

        @State private var selectedIndex = 0
        @FocusState private var isFocused: Bool

        let items: [EntityThumbnail]
        let viewportHeight: CGFloat

        var body: some View {
            Group {
                if let item = selectedItem {
                    hero(item)
                }
            }
            .task(id: items.map(\.id)) {
                selectedIndex = 0
                guard items.count > 1 else { return }

                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(8))
                    guard !Task.isCancelled else { return }
                    guard !isFocused else { continue }
                    select(index: (selectedIndex + 1) % items.count, duration: 0.65)
                }
            }
        }

        private var selectedItem: EntityThumbnail? {
            guard !items.isEmpty else { return nil }
            return items[min(selectedIndex, items.count - 1)]
        }

        private func hero(_ item: EntityThumbnail) -> some View {
            ZStack(alignment: .bottomLeading) {
                Color.black.overlay {
                    RemotePosterImage(
                        path: item.bestHeroPath,
                        previewPath: item.bestCoverPath,
                        fallbackSeed: item.title,
                        systemImage: "play.rectangle",
                        retainsCurrentImageWhileLoading: true,
                        maxPixelSize: 2_048
                    )
                    .id(item.id)
                    .transition(.opacity)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.18), .black.opacity(0.96)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                LinearGradient(
                    colors: [.black.opacity(0.78), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                heroCopy(item)
                if items.count > 1 { pageIndicators }
            }
            .frame(maxWidth: .infinity)
            .frame(height: max(720, viewportHeight))
            .clipped()
            .accessibilityIdentifier("tv.home.hero")
        }

        private func heroCopy(_ item: EntityThumbnail) -> some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
                Text(heroEyebrow(for: item))
                    .font(.headline.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(PrismediaColor.accent)
                Text(item.title)
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(PrismediaColor.onMedia)
                    .lineLimit(2)
                NavigationLink(value: EntityLink(thumbnail: item)) {
                    Label(heroAction(for: item), systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PrismediaColor.onMedia)
                }
                .buttonStyle(.glass)
                .controlSize(.large)
                .focused($isFocused)
                .onMoveCommand(perform: handleMove)
            }
            .zIndex(2)
            .padding(.horizontal, 92)
            .padding(.bottom, 76)
        }

        private var pageIndicators: some View {
            HStack(spacing: PrismediaSpacing.medium) {
                ForEach(items) { item in
                    let selected = item.id == selectedItem?.id
                    Capsule()
                        .fill(selected ? .white : .white.opacity(0.38))
                        .frame(width: selected ? 30 : 10, height: 7)
                        .animation(
                            reduceMotion ? nil : .easeInOut(duration: 0.3),
                            value: selectedIndex
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, PrismediaSpacing.section)
            .allowsHitTesting(false)
            .zIndex(3)
        }

        private func handleMove(_ direction: MoveCommandDirection) {
            let action = TVHomeHeroMovePolicy.action(
                for: moveDirection(from: direction),
                isFocused: isFocused,
                selectedIndex: selectedIndex,
                itemCount: items.count
            )

            switch action {
            case .none:
                break
            case .select(let index):
                select(index: index, duration: 0.35)
            case .focusTabs:
                isFocused = false
                tabFocusCoordinator.requestFocus()
            }
        }

        private func moveDirection(
            from direction: MoveCommandDirection
        ) -> TVHomeHeroMoveDirection {
            switch direction {
            case .up: .up
            case .left: .left
            case .right: .right
            default: .other
            }
        }

        private func select(index: Int, duration: Double) {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: duration)) {
                selectedIndex = index
            }
        }

        private func heroEyebrow(for item: EntityThumbnail) -> String {
            (item.resumeSeconds ?? 0) > 1 || (item.progress ?? 0) > 0
                ? "UP NEXT"
                : item.kind.displayLabel.uppercased()
        }

        private func heroAction(for item: EntityThumbnail) -> String {
            (item.resumeSeconds ?? 0) > 1 || (item.progress ?? 0) > 0
                ? "Resume"
                : "View Details"
        }
    }
#endif
#if os(tvOS) && DEBUG
    #Preview("TV Home Hero · One Item · Accessibility Type") {
        @Previewable @State var tabFocusCoordinator = TVTabFocusCoordinator()
        PreviewShell {
            NavigationStack {
                TVHomeHero(
                    items: [TVHomePreviewLoader().item],
                    viewportHeight: 1_080
                )
            }
        }
        .environment(tabFocusCoordinator)
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
