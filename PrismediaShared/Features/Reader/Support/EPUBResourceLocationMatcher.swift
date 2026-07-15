import Foundation

struct EPUBResourceLocationMatcher: Sendable {
    func bestMatch(for requestedLocation: String, candidates: [String]) -> String? {
        if let exact = candidates.first(where: { $0 == requestedLocation }) {
            return exact
        }

        let requested = normalizedLocation(requestedLocation)
        if let normalized = candidates.first(where: { normalizedLocation($0) == requested }) {
            return normalized
        }

        let resourceMatches = candidates.filter {
            normalizedResource($0) == normalizedResource(requestedLocation)
        }
        if let resourceMatch = uniqueResourceMatch(resourceMatches) {
            return resourceMatch
        }

        let requestedResource = normalizedResource(requestedLocation)
        guard !requestedResource.isEmpty else { return nil }
        let suffixMatches = candidates.filter { candidate in
            let candidateResource = normalizedResource(candidate)
            return candidateResource.hasSuffix("/\(requestedResource)")
                || requestedResource.hasSuffix("/\(candidateResource)")
        }
        return uniqueResourceMatch(suffixMatches)
    }

    private func uniqueResourceMatch(_ candidates: [String]) -> String? {
        guard let first = candidates.first else { return nil }
        let resources = Set(candidates.map(normalizedResource))
        return resources.count == 1 ? first : nil
    }

    private func normalizedLocation(_ location: String) -> String {
        let parts = location.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
        let resource = normalizedResource(String(parts[0]))
        guard parts.count == 2 else { return resource }
        let fragment = String(parts[1]).removingPercentEncoding ?? String(parts[1])
        return "\(resource)#\(fragment.lowercased())"
    }

    private func normalizedResource(_ location: String) -> String {
        var resource = location.split(separator: "#", maxSplits: 1).first.map(String.init) ?? location
        resource = resource.split(separator: "?", maxSplits: 1).first.map(String.init) ?? resource
        resource = (resource.removingPercentEncoding ?? resource)
            .replacingOccurrences(of: "\\", with: "/")

        var components: [Substring] = []
        for component in resource.split(separator: "/") {
            if component == "." { continue }
            if component == ".." {
                if !components.isEmpty { components.removeLast() }
                continue
            }
            components.append(component)
        }
        return components.joined(separator: "/").lowercased()
    }
}
