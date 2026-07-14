import Foundation

private struct PreviewHTTPDataLoader: HTTPDataLoading {
    let items: [EntityThumbnail]

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else { throw URLError(.badURL) }
        let response = HTTPURLResponse(
            url: url,
            statusCode: url.path == "/api/entities" ? 200 : 404,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        guard url.path == "/api/entities" else {
            return (Data("{}".utf8), response)
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let kind = components?.queryItems?
            .first { $0.name.caseInsensitiveCompare("kind") == .orderedSame }?
            .value
            .map(EntityKind.init(rawValue:))
        let search = components?.queryItems?
            .first { $0.name.caseInsensitiveCompare("search") == .orderedSame }?
            .value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = items.filter { item in
            let matchesKind = kind == nil || item.kind == kind
            let matchesSearch =
                search?.isEmpty != false
                || item.title.localizedCaseInsensitiveContains(search ?? "")
            return matchesKind && matchesSearch
        }
        let payload: [String: Any] = [
            "items": filtered.map(Self.jsonObject),
            "totalCount": filtered.count,
            "nextCursor": NSNull(),
        ]
        return (try JSONSerialization.data(withJSONObject: payload), response)
    }

    private static func jsonObject(_ item: EntityThumbnail) -> [String: Any] {
        var object: [String: Any] = [
            "id": item.id.uuidString,
            "kind": item.kind.rawValue,
            "title": item.title,
            "isFavorite": item.isFavorite,
            "isNsfw": item.isNsfw,
            "isOrganized": item.isOrganized,
            "isWanted": item.isWanted,
            "hasSourceMedia": item.hasSourceMedia,
            "genres": item.genres,
            "meta": item.meta.map { ["icon": $0.icon, "label": $0.label] },
        ]
        if let coverURL = item.coverURL { object["coverUrl"] = coverURL }
        if let progress = item.progress { object["progress"] = progress }
        if let resumeSeconds = item.resumeSeconds { object["resumeSeconds"] = resumeSeconds }
        if let playCount = item.playCount { object["playCount"] = playCount }
        if let rating = item.rating { object["rating"] = rating }
        return object
    }
}

func makePreviewHTTPDataLoader(items: [EntityThumbnail]) -> some HTTPDataLoading {
    PreviewHTTPDataLoader(items: items)
}
