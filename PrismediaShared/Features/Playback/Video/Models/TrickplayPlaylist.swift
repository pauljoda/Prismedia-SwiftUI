import Foundation

public struct TrickplayPlaylist: Equatable, Sendable {
    public struct Frame: Equatable, Sendable {
        public let startTime: TimeInterval
        public let imageURL: URL
        public let crop: Crop
        public let imageWidth: Int
        public let imageHeight: Int

        public init(
            startTime: TimeInterval,
            imageURL: URL,
            crop: Crop,
            imageWidth: Int,
            imageHeight: Int
        ) {
            self.startTime = startTime
            self.imageURL = imageURL
            self.crop = crop
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
        }
    }

    public struct Crop: Equatable, Sendable {
        public let x: Int
        public let y: Int
        public let width: Int
        public let height: Int

        public init(x: Int, y: Int, width: Int, height: Int) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }
    }

    public enum ParseError: Error, Equatable, Sendable {
        case missingTileMetadata
        case invalidTileMetadata
        case invalidSegmentDuration
        case invalidImageURL(String)
        case invalidWebVTT
    }

    public let frames: [Frame]

    public init(frames: [Frame]) {
        self.frames = frames
    }

    public func frame(at time: TimeInterval) -> Frame? {
        guard !frames.isEmpty else { return nil }
        let target = time.isFinite ? time : 0
        var lowerBound = 0
        var upperBound = frames.count

        while lowerBound < upperBound {
            let midpoint = (lowerBound + upperBound) / 2
            if frames[midpoint].startTime <= target {
                lowerBound = midpoint + 1
            } else {
                upperBound = midpoint
            }
        }
        return frames[max(0, lowerBound - 1)]
    }

    public static func parse(contents: String, playlistURL: URL) throws -> Self {
        if contents.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("WEBVTT") {
            return try parseWebVTT(contents: contents, playlistURL: playlistURL)
        }
        var parser = Parser(playlistURL: playlistURL)
        return try parser.parse(contents)
    }

    private static func parseWebVTT(contents: String, playlistURL: URL) throws -> Self {
        let lines = contents.components(separatedBy: .newlines)
        var rawFrames: [(startTime: TimeInterval, imageURL: URL, crop: Crop)] = []
        var pendingStartTime: TimeInterval?

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.contains("-->") {
                let start = line.components(separatedBy: "-->")[0]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                pendingStartTime = parseWebVTTTimestamp(start)
                continue
            }

            guard let startTime = pendingStartTime, !line.isEmpty, !line.hasPrefix("NOTE") else {
                continue
            }
            pendingStartTime = nil
            guard
                let fragmentRange = line.range(of: "#xywh="),
                let imageURL = URL(
                    string: String(line[..<fragmentRange.lowerBound]),
                    relativeTo: playlistURL
                )?.absoluteURL
            else {
                throw ParseError.invalidWebVTT
            }
            let values = line[fragmentRange.upperBound...].split(separator: ",", maxSplits: 3)
            guard
                values.count == 4,
                let x = Int(values[0]),
                let y = Int(values[1]),
                let width = Int(values[2]),
                let height = Int(values[3]),
                x >= 0, y >= 0, width > 0, height > 0
            else {
                throw ParseError.invalidWebVTT
            }
            rawFrames.append(
                (startTime, imageURL, Crop(x: x, y: y, width: width, height: height))
            )
        }

        guard !rawFrames.isEmpty else { throw ParseError.invalidWebVTT }
        let imageExtents = Dictionary(grouping: rawFrames, by: \.imageURL).mapValues { frames in
            (
                width: frames.map { $0.crop.x + $0.crop.width }.max() ?? 0,
                height: frames.map { $0.crop.y + $0.crop.height }.max() ?? 0
            )
        }
        return TrickplayPlaylist(
            frames: rawFrames.map { rawFrame in
                let extent = imageExtents[rawFrame.imageURL]
                return Frame(
                    startTime: rawFrame.startTime,
                    imageURL: rawFrame.imageURL,
                    crop: rawFrame.crop,
                    imageWidth: extent?.width ?? rawFrame.crop.width,
                    imageHeight: extent?.height ?? rawFrame.crop.height
                )
            }
        )
    }

    private static func parseWebVTTTimestamp(_ value: String) -> TimeInterval? {
        let components = value.split(separator: ":")
        guard components.count == 2 || components.count == 3 else { return nil }
        guard let seconds = TimeInterval(components[components.count - 1]) else { return nil }
        guard let minutes = TimeInterval(components[components.count - 2]) else { return nil }
        let hours: TimeInterval
        if components.count == 3 {
            guard let parsedHours = TimeInterval(components[0]) else { return nil }
            hours = parsedHours
        } else {
            hours = 0
        }
        guard hours >= 0, minutes >= 0, seconds >= 0 else { return nil }
        return (hours * 3_600) + (minutes * 60) + seconds
    }
}

extension TrickplayPlaylist {
    fileprivate struct TileMetadata {
        let width: Int
        let height: Int
        let columns: Int
        let rows: Int
        let duration: TimeInterval

        var capacity: Int { columns * rows }

        func crop(at index: Int) -> Crop {
            Crop(
                x: (index % columns) * width,
                y: (index / columns) * height,
                width: width,
                height: height
            )
        }
    }

    fileprivate struct Parser {
        let playlistURL: URL
        var metadata: TileMetadata?
        var pendingSegmentDuration: TimeInterval?
        var elapsedTime: TimeInterval = 0
        var frames: [Frame] = []

        mutating func parse(_ contents: String) throws -> TrickplayPlaylist {
            for rawLine in contents.components(separatedBy: .newlines) {
                try parseLine(rawLine.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            return TrickplayPlaylist(frames: frames)
        }

        mutating func parseLine(_ line: String) throws {
            guard !line.isEmpty else { return }
            if line.hasPrefix("#EXT-X-TILES:") {
                metadata = try Self.parseMetadata(line)
                return
            }
            if line.hasPrefix("#EXTINF:") {
                pendingSegmentDuration = try Self.parseSegmentDuration(line)
                return
            }
            guard !line.hasPrefix("#"), let segmentDuration = pendingSegmentDuration else { return }
            try appendFrames(imageReference: line, segmentDuration: segmentDuration)
            pendingSegmentDuration = nil
        }

        mutating func appendFrames(imageReference: String, segmentDuration: TimeInterval) throws {
            guard let metadata else { throw ParseError.missingTileMetadata }
            guard let imageURL = URL(string: imageReference, relativeTo: playlistURL)?.absoluteURL else {
                throw ParseError.invalidImageURL(imageReference)
            }
            let frameCount = min(metadata.capacity, Int(ceil(segmentDuration / metadata.duration)))
            for index in 0..<frameCount {
                frames.append(
                    Frame(
                        startTime: elapsedTime + (Double(index) * metadata.duration),
                        imageURL: imageURL,
                        crop: metadata.crop(at: index),
                        imageWidth: metadata.width * metadata.columns,
                        imageHeight: metadata.height * metadata.rows
                    )
                )
            }
            elapsedTime += segmentDuration
        }

        static func parseMetadata(_ line: String) throws -> TileMetadata {
            let attributes = parseAttributes(String(line.dropFirst("#EXT-X-TILES:".count)))
            guard
                let resolution = dimensions(attributes["RESOLUTION"]),
                let layout = dimensions(attributes["LAYOUT"]),
                let durationText = attributes["DURATION"],
                let duration = TimeInterval(durationText),
                duration > 0
            else {
                throw ParseError.invalidTileMetadata
            }
            return TileMetadata(
                width: resolution.width,
                height: resolution.height,
                columns: layout.width,
                rows: layout.height,
                duration: duration
            )
        }

        static func parseSegmentDuration(_ line: String) throws -> TimeInterval {
            let value = line.dropFirst("#EXTINF:".count).split(separator: ",", maxSplits: 1)[0]
            guard let duration = TimeInterval(value), duration > 0 else {
                throw ParseError.invalidSegmentDuration
            }
            return duration
        }

        static func parseAttributes(_ value: String) -> [String: String] {
            value.split(separator: ",").reduce(into: [:]) { attributes, component in
                let pair = component.split(separator: "=", maxSplits: 1)
                guard pair.count == 2 else { return }
                attributes[String(pair[0]).trimmingCharacters(in: .whitespaces)] =
                    String(pair[1]).trimmingCharacters(in: .whitespaces)
            }
        }

        static func dimensions(_ value: String?) -> (width: Int, height: Int)? {
            guard let value else { return nil }
            let components = value.lowercased().split(separator: "x", maxSplits: 1)
            guard
                components.count == 2,
                let width = Int(components[0]),
                let height = Int(components[1]),
                width > 0,
                height > 0
            else {
                return nil
            }
            return (width, height)
        }
    }
}
