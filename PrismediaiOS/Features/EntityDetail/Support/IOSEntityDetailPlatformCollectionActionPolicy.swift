#if os(iOS)
    enum EntityDetailPlatformCollectionActionPolicy {
        static func adapt(_ policy: EntityGridActionPolicy) -> EntityGridActionPolicy {
            policy
        }

        static func mutationService(
            _ service: (any EntityGridMutationServicing)?
        ) -> (any EntityGridMutationServicing)? {
            service
        }
    }
#endif
