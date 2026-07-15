import SwiftUI

public struct PrismediaLoadingView: View {
    private let title: LocalizedStringKey
    private let launchBrandNamespace: Namespace.ID?

    public init(_ title: LocalizedStringKey) {
        self.title = title
        launchBrandNamespace = nil
    }

    init(_ title: LocalizedStringKey, launchBrandNamespace: Namespace.ID) {
        self.title = title
        self.launchBrandNamespace = launchBrandNamespace
    }

    public var body: some View {
        VStack {
            Spacer()

            VStack(spacing: PrismediaSpacing.medium) {
                PrismediaLoadingMark(launchBrandNamespace: launchBrandNamespace)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityRepresentation {
            ProgressView {
                Text(title)
            }
        }
    }
}

#if DEBUG
    #Preview("Loading · Dark") {
        ZStack {
            PrismediaBackdrop()
            PrismediaLoadingView("Loading library…")
        }
        .preferredColorScheme(.dark)
    }

    #Preview("Loading · Accessibility") {
        ZStack {
            PrismediaBackdrop()
            PrismediaLoadingView("Loading your Prismedia library…")
        }
        .environment(\.dynamicTypeSize, .accessibility3)
        .preferredColorScheme(.dark)
    }
#endif
