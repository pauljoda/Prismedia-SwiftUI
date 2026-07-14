import SwiftUI

struct EntityImageZoomView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale = 1.0
    @State private var offset = CGSize.zero
    @GestureState private var gestureScale = 1.0
    @GestureState private var gestureOffset = CGSize.zero

    let image: Image
    let title: String
    let showsControls: Bool

    init(
        image: Image,
        title: String,
        showsControls: Bool = true
    ) {
        self.image = image
        self.title = title
        self.showsControls = showsControls
    }

    @ViewBuilder
    var body: some View {
        #if os(tvOS)
            imageCanvas
                .accessibilityLabel(title)
        #else
            imageCanvas
                .toolbar {
                    #if os(iOS)
                        if showsControls {
                            ToolbarItemGroup(placement: .bottomBar) {
                                zoomButtons
                            }
                        }
                    #elseif os(macOS)
                        if showsControls {
                            ToolbarItemGroup(placement: .primaryAction) {
                                zoomButtons
                            }
                        }
                    #endif
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(title)
                .accessibilityValue("Zoom \(Int(displayScale * 100)) percent")
                .accessibilityAdjustableAction(adjustZoom)
        #endif
    }

    private var imageCanvas: some View {
        GeometryReader { geometry in
            #if os(tvOS)
                fittedImage(in: geometry)
            #else
                fittedImage(in: geometry)
                    .scaleEffect(displayScale)
                    .offset(displayOffset)
                    .contentShape(Rectangle())
                    .gesture(magnifyGesture)
                    .simultaneousGesture(panGesture)
                    .onTapGesture(count: 2, perform: toggleZoom)
            #endif
        }
        .clipped()
    }

    private func fittedImage(in geometry: GeometryProxy) -> some View {
        image
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width, height: geometry.size.height)
    }

    private var displayScale: Double {
        min(max(scale * gestureScale, 1), 6)
    }

    private var displayOffset: CGSize {
        guard displayScale > 1 else { return .zero }
        return CGSize(
            width: offset.width + gestureOffset.width,
            height: offset.height + gestureOffset.height
        )
    }

    #if !os(tvOS)
        private var magnifyGesture: some Gesture {
            MagnifyGesture()
                .updating($gestureScale) { value, state, _ in
                    state = value.magnification
                }
                .onEnded { value in
                    scale = min(max(scale * value.magnification, 1), 6)
                    if scale == 1 { offset = .zero }
                }
        }

        private var panGesture: some Gesture {
            DragGesture(minimumDistance: displayScale > 1 ? 8 : .infinity)
                .updating($gestureOffset) { value, state, _ in
                    guard displayScale > 1 else { return }
                    state = value.translation
                }
                .onEnded { value in
                    guard displayScale > 1 else { return }
                    offset.width += value.translation.width
                    offset.height += value.translation.height
                }
        }
    #endif

    @ViewBuilder
    private var zoomButtons: some View {
        zoomOutButton
        actualSizeButton
        zoomInButton
    }

    private var zoomOutButton: some View {
        Button("Zoom Out", systemImage: "minus.magnifyingglass") {
            setZoom(scale - 0.5)
        }
        .disabled(scale <= 1)
    }

    private var actualSizeButton: some View {
        Button("Actual Size", systemImage: "1.magnifyingglass") {
            setZoom(1)
        }
        .disabled(scale == 1)
    }

    private var zoomInButton: some View {
        Button("Zoom In", systemImage: "plus.magnifyingglass") {
            setZoom(scale + 0.5)
        }
        .disabled(scale >= 6)
    }

    private func toggleZoom() {
        setZoom(scale > 1 ? 1 : 2)
    }

    private func adjustZoom(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment: setZoom(scale + 0.5)
        case .decrement: setZoom(scale - 0.5)
        @unknown default: break
        }
    }

    private func setZoom(_ value: Double) {
        let update = {
            scale = min(max(value, 1), 6)
            if scale == 1 { offset = .zero }
        }
        if reduceMotion {
            update()
        } else {
            withAnimation(.easeOut(duration: 0.18), update)
        }
    }
}

#if DEBUG
    #Preview("Image Zoom") {
        EntityImageZoomView(
            image: Image(systemName: "photo.on.rectangle.angled"),
            title: "Preview Image"
        )
        .background(.black)
    }
#endif
