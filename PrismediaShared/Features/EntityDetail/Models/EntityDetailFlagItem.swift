struct EntityDetailFlagItem: Identifiable {
    let title: String
    let systemImage: String
    let tone: EntityDetailFlagTone
    var id: String { title }
}
