enum EntityDetailPrimaryActionPolicy {
    static func tintedActionID(in actions: [EntityDetailAction]) -> EntityDetailActionID? {
        actions.first?.id
    }
}
