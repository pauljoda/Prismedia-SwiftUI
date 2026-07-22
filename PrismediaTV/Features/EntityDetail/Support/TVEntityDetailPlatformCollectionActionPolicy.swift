#if os(tvOS)
    enum EntityDetailPlatformCollectionActionPolicy {
        static func adapt(_ policy: EntityGridActionPolicy) -> EntityGridActionPolicy {
            .disabled
        }

        static func mutationService(
            _ service: (any EntityGridMutationServicing)?
        ) -> (any EntityGridMutationServicing)? {
            nil
        }
    }
#endif
