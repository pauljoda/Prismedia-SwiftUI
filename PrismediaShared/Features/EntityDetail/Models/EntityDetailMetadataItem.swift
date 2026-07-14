import Foundation

struct EntityDetailMetadataItem: Identifiable, Hashable {
    let label: String
    let value: String
    let systemImage: String
    let url: URL?
    var id: String { "\(label):\(value)" }

    init(
        label: String,
        value: String,
        systemImage: String,
        url: URL? = nil
    ) {
        self.label = label
        self.value = value
        self.systemImage = systemImage
        self.url = url
    }
}
