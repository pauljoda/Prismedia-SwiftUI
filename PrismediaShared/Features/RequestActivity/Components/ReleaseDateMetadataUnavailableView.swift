import SwiftUI

#if os(iOS) || os(macOS)
    struct ReleaseDateMetadataUnavailableView: View {
        let onEnterReleaseDate: @MainActor @Sendable () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Label("Release date unavailable", systemImage: "calendar.badge.exclamationmark")
                    .font(.headline)
                    .foregroundStyle(PrismediaColor.warning)
                Text("The configured metadata provider did not return the required release milestone. You can keep waiting for future metadata or enter a keyed date now.")
                    .foregroundStyle(PrismediaColor.textSecondary)
                PrismediaButton("Enter release date", systemImage: "calendar.badge.plus") {
                    onEnterReleaseDate()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier("acquisition.release-date-metadata-unavailable")
        }
    }
#endif

#if DEBUG && (os(iOS) || os(macOS))
    #Preview("Release Date Metadata Unavailable") {
        ReleaseDateMetadataUnavailableView(onEnterReleaseDate: {})
            .padding()
            .preferredColorScheme(.dark)
    }
#endif
