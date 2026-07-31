# Prismedia Native API Backlog

The SwiftUI app consumes Prismedia's entity, capability, playback, and administration contracts directly. These are the remaining API gaps to watch as the native client grows:

1. Dashboard endpoint
   - Needed shape: grouped rails for videos, series, galleries, books, collections, and resume items.
   - Why: the web dashboard currently composes several list calls client-side; native should avoid extra startup round trips.

2. Entity grid query parity
   - Needed shape: server-side sort, filter, saved preset, pagination, and NSFW controls for the same EntityGrid concepts used on the web.
   - Why: the prototype can locally sort/filter the loaded page, but a native client should not pretend that page-local filtering covers the full library.

3. Image URL contract
   - Needed shape: stable cover, thumbnail, backdrop, and preview fields with dimensions and blurhash or dominant color.
   - Why: SwiftUI wants predictable layout before images arrive.

4. Reader and lightbox manifests
   - Needed shape: ordered page/image manifests, navigation context, resume targets, and prefetch hints for books, galleries, and image collections.
   - Why: the SwiftUI prototype reserves reader and lightbox sheets, but native interaction needs explicit ordered media payloads.

5. Files browser endpoint
   - Needed shape: source roots, directory children, scan status, matched entity references, and file actions in one Prismedia-native contract.
   - Why: Files is present in the mobile tab shell, but should not be wired to a generic entity list.

6. Capability projection for Apple clients
   - Needed shape: server-returned media technical metadata plus server recommendation for Apple direct play.
   - Why: the app can know platform capability, but the server owns file/probe truth.
