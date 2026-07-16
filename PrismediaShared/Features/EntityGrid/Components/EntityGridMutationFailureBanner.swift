import SwiftUI

struct EntityGridMutationFailureBanner: View {
    let failures: [EntityGridMutationFailure]

    var body: some View {
        VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
            Label(
                "\(failures.count) item\(failures.count == 1 ? "" : "s") still need attention",
                systemImage: "exclamationmark.triangle"
            )
            .font(.callout.weight(.semibold))
            .foregroundStyle(PrismediaColor.destructive)

            Text("Failed items remain selected. Review the details and retry the action.")
                .font(.footnote)
                .foregroundStyle(PrismediaColor.textSecondary)

            ForEach(failures.prefix(3), id: \.entityID) { failure in
                Text("\(failure.title): \(failure.message)")
                    .font(.caption)
                    .foregroundStyle(PrismediaColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(PrismediaSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismediaPanel()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("entity.grid.selection.failures")
    }
}

#if DEBUG
    #Preview("Partial Failure · Compact") {
        EntityGridMutationFailureBanner(
            failures: [
                EntityGridMutationFailure(
                    entityID: UUID(),
                    title: "Arrival",
                    message: "The server is still stopping its download."
                ),
                EntityGridMutationFailure(
                    entityID: UUID(),
                    title: "Dune",
                    message: "The collection is dynamic and must be changed through its rules."
                ),
            ]
        )
        .padding()
        .frame(width: 340)
        .preferredColorScheme(.dark)
    }

    #Preview("Partial Failure · Accessibility") {
        EntityGridMutationFailureBanner(
            failures: [
                EntityGridMutationFailure(
                    entityID: UUID(),
                    title: "A Very Long Selected Item Title",
                    message: "The request could not complete, so this item remains selected for retry."
                )
            ]
        )
        .padding()
        .frame(width: 620)
        .environment(\.dynamicTypeSize, .accessibility3)
    }
#endif
