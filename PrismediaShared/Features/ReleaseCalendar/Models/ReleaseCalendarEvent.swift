import Foundation

public struct ReleaseCalendarEvent: Decodable, Hashable, Identifiable, Sendable {
    public let entityID: UUID
    public let monitorID: UUID
    public let acquisitionID: UUID?
    public let kind: EntityKind
    public let title: String
    public let parentEntityID: UUID?
    public let parentKind: EntityKind?
    public let parentTitle: String?
    public let dateType: EntityDateType
    public let value: String
    public let date: String
    public let precision: DatePrecision
    public let acquisitionStatus: AcquisitionStatus?
    public let isSearchGate: Bool
    public let searchNotBefore: String?
    public let isSearchEligible: Bool?
    public let posterURL: String?

    public var id: String {
        "\(monitorID.uuidString):\(dateType.rawValue):\(date)"
    }

    public init(
        entityID: UUID,
        monitorID: UUID,
        acquisitionID: UUID? = nil,
        kind: EntityKind,
        title: String,
        parentEntityID: UUID? = nil,
        parentKind: EntityKind? = nil,
        parentTitle: String? = nil,
        dateType: EntityDateType,
        value: String,
        date: String,
        precision: DatePrecision,
        acquisitionStatus: AcquisitionStatus? = nil,
        isSearchGate: Bool = false,
        searchNotBefore: String? = nil,
        isSearchEligible: Bool? = nil,
        posterURL: String? = nil
    ) {
        self.entityID = entityID
        self.monitorID = monitorID
        self.acquisitionID = acquisitionID
        self.kind = kind
        self.title = title
        self.parentEntityID = parentEntityID
        self.parentKind = parentKind
        self.parentTitle = parentTitle
        self.dateType = dateType
        self.value = value
        self.date = date
        self.precision = precision
        self.acquisitionStatus = acquisitionStatus
        self.isSearchGate = isSearchGate
        self.searchNotBefore = searchNotBefore
        self.isSearchEligible = isSearchEligible
        self.posterURL = posterURL
    }

    private enum CodingKeys: String, CodingKey {
        case entityID = "entityId"
        case monitorID = "monitorId"
        case acquisitionID = "acquisitionId"
        case kind, title
        case parentEntityID = "parentEntityId"
        case parentKind, parentTitle, dateType, value, date, precision
        case acquisitionStatus, isSearchGate, searchNotBefore, isSearchEligible
        case posterURL = "posterUrl"
    }
}
