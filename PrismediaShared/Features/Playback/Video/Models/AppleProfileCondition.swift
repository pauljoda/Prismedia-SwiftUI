struct AppleProfileCondition: Encodable {
    let condition: String
    let property: String
    let value: String
    let isRequired: Bool

    enum CodingKeys: String, CodingKey {
        case condition = "Condition"
        case property = "Property"
        case value = "Value"
        case isRequired = "IsRequired"
    }
}
