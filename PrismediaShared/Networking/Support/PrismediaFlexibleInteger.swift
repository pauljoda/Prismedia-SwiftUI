import Foundation

struct PrismediaFlexibleInteger: Decodable, Sendable {
    let value: Int

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self.value = value
            return
        }
        let value = try container.decode(String.self)
        guard let parsedValue = Int(value) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an integer."
            )
        }
        self.value = parsedValue
    }
}
