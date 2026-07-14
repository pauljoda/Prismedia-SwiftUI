import SwiftUI

/// Reveals the shared spectral content layer behind a full-page generic surface.
public struct PrismediaScreenBackgroundModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        #if os(iOS)
            content
                .scrollContentBackground(.hidden)
                .containerBackground(for: .navigation) { PrismediaBackdrop() }
                .background { PrismediaBackdrop() }
        #elseif os(tvOS)
            content
                .background { PrismediaBackdrop() }
        #else
            content
                .scrollContentBackground(.hidden)
                .background { PrismediaBackdrop() }
        #endif
    }
}

extension View {
    public func prismediaScreenBackground() -> some View {
        modifier(PrismediaScreenBackgroundModifier())
    }
}

#if DEBUG
    #Preview("Screen Background") {
        NavigationStack {
            List {
                Label("Spectral content layer", systemImage: "sparkles")
                Text("System navigation and controls remain above the content background.")
            }
            .navigationTitle("Prismedia")
        }
        .modifier(PrismediaScreenBackgroundModifier())
        .preferredColorScheme(.dark)
    }
#endif
