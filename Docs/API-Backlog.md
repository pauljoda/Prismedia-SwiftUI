# Prismedia Native API Backlog

The SwiftUI app starts against Prismedia-native API routes instead of Jellyfin compatibility routes. These are the first gaps to watch as the native client grows:

1. Playback negotiation endpoint
   - Needed shape: direct-play, remux, HLS, and transcode choices returned as one explicit plan.
   - Why: native AVPlayer capability is stronger than the browser profile, but the app should not infer server decisions from URL shape alone.

2. Dashboard endpoint
   - Needed shape: grouped rails for videos, series, galleries, books, collections, and resume items.
   - Why: the web dashboard currently composes several list calls client-side; native should avoid extra startup round trips.

3. Entity grid query parity
   - Needed shape: server-side sort, filter, saved preset, pagination, and NSFW controls for the same EntityGrid concepts used on the web.
   - Why: the prototype can locally sort/filter the loaded page, but a native client should not pretend that page-local filtering covers the full library.

4. Image URL contract
   - Needed shape: stable cover, thumbnail, backdrop, and preview fields with dimensions and blurhash or dominant color.
   - Why: SwiftUI wants predictable layout before images arrive.

5. Native playback progress
   - Needed shape: heartbeat, seek, stopped, completed, and resume progress routes that are not Jellyfin-session-shaped.
   - Why: AVPlayer should report accurate progress without pretending to be a Jellyfin profile.

6. Reader and lightbox manifests
   - Needed shape: ordered page/image manifests, navigation context, resume targets, and prefetch hints for books, galleries, and image collections.
   - Why: the SwiftUI prototype reserves reader and lightbox sheets, but native interaction needs explicit ordered media payloads.

7. Files browser endpoint
   - Needed shape: source roots, directory children, scan status, matched entity references, and file actions in one Prismedia-native contract.
   - Why: Files is present in the mobile tab shell, but should not be wired to a generic entity list.

8. Capability projection for Apple clients
   - Needed shape: server-returned media technical metadata plus server recommendation for Apple direct play.
   - Why: the app can know platform capability, but the server owns file/probe truth.
