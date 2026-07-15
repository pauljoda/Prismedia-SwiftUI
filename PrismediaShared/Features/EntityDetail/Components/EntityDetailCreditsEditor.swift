import SwiftUI

struct EntityDetailCreditsEditor: View {
    @Binding var credits: [EntityDetailCreditDraft]

    let defaultRole: EntityDetailCreditRole
    let searchService: EntityDetailReferenceSearchService

    var body: some View {
        EntityDetailReferenceSelector(
            selection: people,
            title: "People",
            kind: .person,
            mode: .multiple,
            searchService: searchService
        )

        if !credits.isEmpty {
            Section("Credit Details") {
                ForEach($credits) { $credit in
                    VStack(alignment: .leading, spacing: PrismediaSpacing.small) {
                        HStack {
                            Text(credit.person.title)
                                .font(.headline)
                            Spacer()
                            Button("Remove \(credit.person.title)", systemImage: "minus.circle", role: .destructive) {
                                credits.removeAll { $0.id == credit.id }
                            }
                            .labelStyle(.iconOnly)
                        }

                        if credit.roles.isEmpty {
                            Text("No roles selected")
                                .font(.caption)
                                .foregroundStyle(PrismediaColor.textSecondary)
                        } else {
                            ForEach(credit.roles, id: \.self) { role in
                                HStack {
                                    Text(EntityDetailCreditRole(rawValue: role)?.title ?? role.capitalized)
                                    Spacer()
                                    Button("Remove \(role) role", systemImage: "xmark.circle") {
                                        credit.roles.removeAll { $0 == role }
                                    }
                                    .labelStyle(.iconOnly)
                                }
                            }
                        }

                        Menu("Add Role", systemImage: "plus") {
                            ForEach(availableRoles(for: credit)) { role in
                                Button(role.title) {
                                    credit.roles.append(role.rawValue)
                                }
                            }
                        }

                        TextField("Character or contribution", text: $credit.character)
                    }
                    .padding(.vertical, PrismediaSpacing.extraSmall)
                }
            }
        }
    }

    private var people: Binding<[EntityDetailReferenceDraft]> {
        Binding(
            get: { credits.map(\.person) },
            set: { selectedPeople in
                credits = selectedPeople.map { person in
                    credits.first {
                        EntityDetailReferenceSelectionPolicy.contains(person, in: [$0.person])
                    } ?? EntityDetailCreditDraft(person: person, roles: [defaultRole.rawValue])
                }
            }
        )
    }

    private func availableRoles(for credit: EntityDetailCreditDraft) -> [EntityDetailCreditRole] {
        EntityDetailCreditRole.allCases.filter { !credit.roles.contains($0.rawValue) }
    }
}

#if DEBUG
    #Preview("Entity Detail Credits Editor") {
        @Previewable @State var credits = [
            EntityDetailCreditDraft(
                person: .new(title: "Mara Voss", kind: .person),
                roles: ["actor", "producer"],
                character: "Dr. Hale"
            )
        ]

        PreviewShell {
            NavigationStack {
                Form {
                    EntityDetailCreditsEditor(
                        credits: $credits,
                        defaultRole: .actor,
                        searchService: EntityDetailReferenceSearchService(
                            loader: StaticEntityGridLoader(items: [])
                        )
                    )
                }
            }
        }
    }
#endif
