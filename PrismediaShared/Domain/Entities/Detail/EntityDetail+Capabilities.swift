extension EntityDetail {
    public func capability<Value>(_ type: Value.Type = Value.self) -> Value? {
        capabilities.lazy.compactMap { capability in
            switch capability {
            case .classification(let value): value as? Value
            case .dates(let value): value as? Value
            case .description(let value): value as? Value
            case .fileManagement(let value): value as? Value
            case .files(let value): value as? Value
            case .fingerprints(let value): value as? Value
            case .flags(let value): value as? Value
            case .images(let value): value as? Value
            case .lifetime(let value): value as? Value
            case .links(let value): value as? Value
            case .markers(let value): value as? Value
            case .playback(let value): value as? Value
            case .position(let value): value as? Value
            case .progress(let value): value as? Value
            case .providerIdentity(let value): value as? Value
            case .rating(let value): value as? Value
            case .source(let value): value as? Value
            case .stats(let value): value as? Value
            case .subtitles(let value): value as? Value
            case .technical(let value): value as? Value
            case .unknown(let value): value as? Value
            }
        }.first
    }
}
