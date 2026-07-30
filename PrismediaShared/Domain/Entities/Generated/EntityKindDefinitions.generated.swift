// AUTO-GENERATED from Prismedia's backend EntityKind definitions.
// Do not edit by hand. Run `python3 Scripts/generate-entity-kind-definitions.py`.

import Foundation

public extension EntityKind {
    static let audio = Self(rawValue: "audio")
    static let audioLibrary = Self(rawValue: "audio-library")
    static let audioTrack = Self(rawValue: "audio-track")
    static let book = Self(rawValue: "book")
    static let bookVolume = Self(rawValue: "book-volume")
    static let bookChapter = Self(rawValue: "book-chapter")
    static let bookPage = Self(rawValue: "book-page")
    static let collection = Self(rawValue: "collection")
    static let gallery = Self(rawValue: "gallery")
    static let image = Self(rawValue: "image")
    static let musicArtist = Self(rawValue: "music-artist")
    static let bookAuthor = Self(rawValue: "book-author")
    static let person = Self(rawValue: "person")
    static let movie = Self(rawValue: "movie")
    static let studio = Self(rawValue: "studio")
    static let tag = Self(rawValue: "tag")
    static let video = Self(rawValue: "video")
    static let videoSeries = Self(rawValue: "video-series")
    static let videoSeason = Self(rawValue: "video-season")
}

public extension EntityKindIcon {
    static let album = Self(rawValue: "album")
    static let artist = Self(rawValue: "artist")
    static let audio = Self(rawValue: "audio")
    static let author = Self(rawValue: "author")
    static let book = Self(rawValue: "book")
    static let chapter = Self(rawValue: "chapter")
    static let collection = Self(rawValue: "collection")
    static let gallery = Self(rawValue: "gallery")
    static let image = Self(rawValue: "image")
    static let movie = Self(rawValue: "movie")
    static let page = Self(rawValue: "page")
    static let person = Self(rawValue: "person")
    static let season = Self(rawValue: "season")
    static let series = Self(rawValue: "series")
    static let studio = Self(rawValue: "studio")
    static let tag = Self(rawValue: "tag")
    static let track = Self(rawValue: "track")
    static let video = Self(rawValue: "video")
    static let volume = Self(rawValue: "volume")
}

public extension EntityAccentHue {
    static let red = Self(rawValue: "red")
    static let orange = Self(rawValue: "orange")
    static let yellow = Self(rawValue: "yellow")
    static let green = Self(rawValue: "green")
    static let cyan = Self(rawValue: "cyan")
    static let blue = Self(rawValue: "blue")
    static let violet = Self(rawValue: "violet")
    static let magenta = Self(rawValue: "magenta")
}

public extension EntityArtworkFit {
    static let cover = Self(rawValue: "cover")
    static let contain = Self(rawValue: "contain")
}

let generatedEntityKindDefinitions: [EntityKind: EntityKindDefinition] = [
    .audio: EntityKindDefinition(
        kind: .audio,
        displayName: "Audio",
        groupLabel: "Audio",
        category: "Media",
        storageShape: "File",
        presentation: EntityKindPresentation(
            icon: .audio,
            referenceIcon: .audio,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .violet,
            secondaryAccent: .magenta,
            primaryAccentIndex: 6,
            secondaryAccentIndex: 7,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .audioLibrary: EntityKindDefinition(
        kind: .audioLibrary,
        displayName: "Audio Library",
        groupLabel: "Audio Libraries",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .album,
            referenceIcon: .audio,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .violet,
            secondaryAccent: .magenta,
            primaryAccentIndex: 6,
            secondaryAccentIndex: 7,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
    .audioTrack: EntityKindDefinition(
        kind: .audioTrack,
        displayName: "Audio Track",
        groupLabel: "Audio Tracks",
        category: "Media",
        storageShape: "File",
        presentation: EntityKindPresentation(
            icon: .track,
            referenceIcon: .audio,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .violet,
            secondaryAccent: .magenta,
            primaryAccentIndex: 6,
            secondaryAccentIndex: 7,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: false
    ),
    .book: EntityKindDefinition(
        kind: .book,
        displayName: "Book",
        groupLabel: "Books",
        category: "Media",
        storageShape: "Archive",
        presentation: EntityKindPresentation(
            icon: .book,
            referenceIcon: .book,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .cyan,
            secondaryAccent: .blue,
            primaryAccentIndex: 4,
            secondaryAccentIndex: 5,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
    .bookVolume: EntityKindDefinition(
        kind: .bookVolume,
        displayName: "Book Volume",
        groupLabel: "Volumes",
        category: "Media",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .volume,
            referenceIcon: .book,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .cyan,
            secondaryAccent: .blue,
            primaryAccentIndex: 4,
            secondaryAccentIndex: 5,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: false,
        enumeratesIdentifyChildren: true
    ),
    .bookChapter: EntityKindDefinition(
        kind: .bookChapter,
        displayName: "Book Chapter",
        groupLabel: "Chapters",
        category: "Media",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .chapter,
            referenceIcon: .book,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .cyan,
            secondaryAccent: .blue,
            primaryAccentIndex: 4,
            secondaryAccentIndex: 5,
            artworkFit: .cover
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .bookPage: EntityKindDefinition(
        kind: .bookPage,
        displayName: "Book Page",
        groupLabel: "Pages",
        category: "Media",
        storageShape: "ArchiveEntry",
        presentation: EntityKindPresentation(
            icon: .page,
            referenceIcon: .book,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .cyan,
            secondaryAccent: .blue,
            primaryAccentIndex: 4,
            secondaryAccentIndex: 5,
            artworkFit: .cover
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .collection: EntityKindDefinition(
        kind: .collection,
        displayName: "Collection",
        groupLabel: "Collections",
        category: "Collection",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .collection,
            referenceIcon: .collection,
            thumbnailWidth: 16,
            thumbnailHeight: 9,
            primaryAccent: .magenta,
            secondaryAccent: .red,
            primaryAccentIndex: 7,
            secondaryAccentIndex: 0,
            artworkFit: .cover
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .gallery: EntityKindDefinition(
        kind: .gallery,
        displayName: "Gallery",
        groupLabel: "Galleries",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .gallery,
            referenceIcon: .gallery,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .green,
            secondaryAccent: .cyan,
            primaryAccentIndex: 3,
            secondaryAccentIndex: 4,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .image: EntityKindDefinition(
        kind: .image,
        displayName: "Image",
        groupLabel: "Images",
        category: "Media",
        storageShape: "File",
        presentation: EntityKindPresentation(
            icon: .image,
            referenceIcon: .image,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .blue,
            secondaryAccent: .violet,
            primaryAccentIndex: 5,
            secondaryAccentIndex: 6,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .musicArtist: EntityKindDefinition(
        kind: .musicArtist,
        displayName: "Music Artist",
        groupLabel: "Artists",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .artist,
            referenceIcon: .audio,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .violet,
            secondaryAccent: .magenta,
            primaryAccentIndex: 6,
            secondaryAccentIndex: 7,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
    .bookAuthor: EntityKindDefinition(
        kind: .bookAuthor,
        displayName: "Book Author",
        groupLabel: "Authors",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .author,
            referenceIcon: .book,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .cyan,
            secondaryAccent: .blue,
            primaryAccentIndex: 4,
            secondaryAccentIndex: 5,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
    .person: EntityKindDefinition(
        kind: .person,
        displayName: "Person",
        groupLabel: "People",
        category: "Taxonomy",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .person,
            referenceIcon: .person,
            thumbnailWidth: 4,
            thumbnailHeight: 5,
            primaryAccent: .red,
            secondaryAccent: .violet,
            primaryAccentIndex: 0,
            secondaryAccentIndex: 6,
            artworkFit: .cover
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .movie: EntityKindDefinition(
        kind: .movie,
        displayName: "Movie",
        groupLabel: "Movies",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .movie,
            referenceIcon: .video,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .orange,
            secondaryAccent: .yellow,
            primaryAccentIndex: 1,
            secondaryAccentIndex: 2,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: false
    ),
    .studio: EntityKindDefinition(
        kind: .studio,
        displayName: "Studio",
        groupLabel: "Studios",
        category: "Taxonomy",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .studio,
            referenceIcon: .studio,
            thumbnailWidth: 21,
            thumbnailHeight: 9,
            primaryAccent: .orange,
            secondaryAccent: .magenta,
            primaryAccentIndex: 1,
            secondaryAccentIndex: 7,
            artworkFit: .contain
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .tag: EntityKindDefinition(
        kind: .tag,
        displayName: "Tag",
        groupLabel: "Tags",
        category: "Taxonomy",
        storageShape: "None",
        presentation: EntityKindPresentation(
            icon: .tag,
            referenceIcon: .tag,
            thumbnailWidth: 1,
            thumbnailHeight: 1,
            primaryAccent: .green,
            secondaryAccent: .yellow,
            primaryAccentIndex: 3,
            secondaryAccentIndex: 2,
            artworkFit: .cover
        ),
        supportsFileDeletion: false,
        supportsRequests: false,
        enumeratesIdentifyChildren: false
    ),
    .video: EntityKindDefinition(
        kind: .video,
        displayName: "Video",
        groupLabel: "Videos",
        category: "Media",
        storageShape: "File",
        presentation: EntityKindPresentation(
            icon: .video,
            referenceIcon: .video,
            thumbnailWidth: 16,
            thumbnailHeight: 9,
            primaryAccent: .red,
            secondaryAccent: .orange,
            primaryAccentIndex: 0,
            secondaryAccentIndex: 1,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: false
    ),
    .videoSeries: EntityKindDefinition(
        kind: .videoSeries,
        displayName: "Video Series",
        groupLabel: "Series",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .series,
            referenceIcon: .video,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .yellow,
            secondaryAccent: .green,
            primaryAccentIndex: 2,
            secondaryAccentIndex: 3,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
    .videoSeason: EntityKindDefinition(
        kind: .videoSeason,
        displayName: "Video Season",
        groupLabel: "Seasons",
        category: "Media",
        storageShape: "Folder",
        presentation: EntityKindPresentation(
            icon: .season,
            referenceIcon: .video,
            thumbnailWidth: 2,
            thumbnailHeight: 3,
            primaryAccent: .yellow,
            secondaryAccent: .green,
            primaryAccentIndex: 2,
            secondaryAccentIndex: 3,
            artworkFit: .cover
        ),
        supportsFileDeletion: true,
        supportsRequests: true,
        enumeratesIdentifyChildren: true
    ),
]
