import Foundation

struct ComicReaderPreloadKey: Hashable {
    let chapterIDs: [UUID]
    let index: Int
    let options: ComicReaderOptions
}
