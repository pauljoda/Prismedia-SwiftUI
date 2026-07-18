import SwiftUI

struct AdministrativeJobGroupView: View {
    let title: String
    let jobs: [AdministrativeJobRun]
    let statusLabel: String
    let isWorking: Bool
    let onCancel: (AdministrativeJobRun) -> Void

    @State private var isExpanded: Bool

    init(
        title: String,
        jobs: [AdministrativeJobRun],
        statusLabel: String,
        isWorking: Bool,
        initiallyExpanded: Bool = true,
        onCancel: @escaping (AdministrativeJobRun) -> Void
    ) {
        self.title = title
        self.jobs = jobs
        self.statusLabel = statusLabel
        self.isWorking = isWorking
        self.onCancel = onCancel
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        #if os(tvOS)
            VStack(alignment: .leading, spacing: PrismediaSpacing.medium) {
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(.headline)
                        Spacer()
                        Text("\(jobs.count) \(statusLabel)")
                            .font(.caption)
                            .foregroundStyle(PrismediaColor.textSecondary)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }

                if isExpanded {
                    ForEach(jobs) { job in
                        AdministrativeJobRunRow(job: job, isWorking: isWorking, onCancel: onCancel)
                        if job.id != jobs.last?.id { Divider() }
                    }
                }
            }
        #else
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(jobs) { job in
                AdministrativeJobRunRow(job: job, isWorking: isWorking, onCancel: onCancel)
                if job.id != jobs.last?.id { Divider() }
            }
        } label: {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(jobs.count) \(statusLabel)")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textSecondary)
            }
        }
        #endif
    }
}

#if DEBUG
    #Preview("Job Group") {
        List {
            AdministrativeJobGroupView(
                title: "Identify Cascade",
                jobs: [
                    AdministrativeJobRun(
                        id: UUID(),
                        type: "identify-cascade",
                        status: "active",
                        progress: 62,
                        message: "Resolving Season 10",
                        targetKind: "video-series",
                        targetID: nil,
                        targetLabel: "MythBusters",
                        createdAt: .now.addingTimeInterval(-120),
                        startedAt: .now.addingTimeInterval(-90),
                        finishedAt: nil
                    )
                ],
                statusLabel: "running",
                isWorking: false,
                onCancel: { _ in }
            )
        }
    }
#endif
