import Foundation

enum DashboardTrickplayFrameSampler {
    static func sample(
        _ frames: [TrickplayPlaylist.Frame],
        limit: Int
    ) -> [TrickplayPlaylist.Frame] {
        guard limit > 0, !frames.isEmpty else { return [] }
        guard frames.count > limit else { return frames }
        guard limit > 1 else { return [frames[0]] }

        return (0..<limit).map { index in
            let position = Double(index) * Double(frames.count - 1) / Double(limit - 1)
            return frames[Int(position.rounded())]
        }
    }
}
