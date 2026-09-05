import SwiftUI

/// Transfer content uses ordinary native form layout; the parent owns its toolbar and presentation.
struct AdministrativeFileTransferStatusView: View {
    let title: String
    let detail: String
    let progress: Double?
    let isWorking: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.large) {
            Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
            if !detail.isEmpty {
                Text(detail).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            if isWorking {
                if let progress {
                    ProgressView(value: progress)
                        .accessibilityLabel("Transfer progress")
                } else {
                    ProgressView().accessibilityLabel(title)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, PrismediaSpacing.small)
    }
}

#Preview("Progress") {
    Form {
        AdministrativeFileTransferStatusView(
            title: "Creating ZIP", detail: "9 of 20 files", progress: 0.45, isWorking: true)
    }
}
#Preview("Large Text") {
    Form {
        AdministrativeFileTransferStatusView(
            title: "Uploading Files",
            detail: "Books/A very long book title and its companion notes.pdf", progress: 0.45, isWorking: true)
    }.environment(\.dynamicTypeSize, .accessibility3)
}
#Preview("Cancelled") {
    Form {
        AdministrativeFileTransferStatusView(
            title: "Upload Cancelled",
            detail: "2 of 5 files confirmed uploaded. Check the folder before trying again.", progress: nil,
            isWorking: false)
    }
}
