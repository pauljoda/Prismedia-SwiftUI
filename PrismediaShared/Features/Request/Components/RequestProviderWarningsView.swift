import SwiftUI

#if os(iOS) || os(macOS)
    struct RequestProviderWarningsView: View {
        let warnings: [AdministrativeRequestProviderError]

        var body: some View {
            if !warnings.isEmpty {
                VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                    Label("Some providers could not be searched", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    ForEach(warnings) { warning in
                        Text("\(warning.displayName): \(warning.message)")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(PrismediaSpacing.large)
                .prismediaPanel()
                .accessibilityIdentifier("request.provider-warnings")
            }
        }
    }

    #if DEBUG
        #Preview("Request Provider Warnings") {
            RequestProviderWarningsView(warnings: RequestPreviewFixtures.warnings)
                .padding()
        }
    #endif
#endif
