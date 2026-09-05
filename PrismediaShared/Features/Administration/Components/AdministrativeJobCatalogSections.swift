import SwiftUI

struct AdministrativeJobCatalogSections: View {
    let snapshot: AdministrativeJobListResponse
    let isWorking: Bool
    let onRun: (AdministrativeJobCommand) -> Void
    let onConfirm: (AdministrativeJobCommand) -> Void

    var body: some View {
        Section("Scan Libraries") {
            row(
                PrismediaContractCodes.JobType.scanLibrary, title: "Videos", description: "Find new video files.",
                systemImage: "film", accent: PrismediaColor.entityAccent(for: .video), actionTitle: "Scan")
            row(
                PrismediaContractCodes.JobType.scanGallery, title: "Images",
                description: "Find new images and galleries.",
                systemImage: "photo.on.rectangle", accent: PrismediaColor.entityAccent(for: .image), actionTitle: "Scan"
            )
            row(
                PrismediaContractCodes.JobType.scanBook, title: "Books", description: "Find new books and audiobooks.",
                systemImage: "book.closed", accent: PrismediaColor.entityAccent(for: .book), actionTitle: "Scan")
            row(
                PrismediaContractCodes.JobType.scanAudio, title: "Audio", description: "Find new audio tracks.",
                systemImage: "music.note", accent: PrismediaColor.entityAccent(for: .audioTrack), actionTitle: "Scan")
        }
        Section("Maintenance") {
            row(
                PrismediaContractCodes.JobType.refreshCollection, title: "Collections",
                description: "Update collections from their saved rules.", systemImage: "rectangle.stack",
                accent: PrismediaColor.textSecondary, actionTitle: "Refresh")
            row(
                PrismediaContractCodes.JobType.monitoredSearch, title: "Monitored Items",
                description: "Search for missing items and new releases from followed creators.",
                systemImage: "magnifyingglass",
                accent: PrismediaColor.textSecondary, actionTitle: "Check")
        }
    }

    private func row(
        _ type: String, title: String, description: String, systemImage: String,
        accent: Color, actionTitle: String
    ) -> some View {
        AdministrativeJobCatalogRow(
            title: title, description: description, systemImage: systemImage,
            activeCount: snapshot.count(type: type, statuses: AdministrativeJobListResponse.activeStatuses),
            queuedCount: snapshot.count(type: type, statuses: AdministrativeJobListResponse.queuedStatuses),
            failedCount: snapshot.count(type: type, statuses: AdministrativeJobListResponse.failedStatuses),
            isWorking: isWorking, accent: accent, actionTitle: actionTitle,
            onRun: { onRun(.run(type: type)) }, onStop: { onConfirm(.stop(type: type)) },
            onClearFailures: { onConfirm(.clearFailures(type: type)) })
    }
}
