#if DEBUG
    import Foundation

    enum EntityDetailPreviewFixture {
        static let detail: EntityDetail = {
            let json = """
                {
                  "id": "99999999-9999-9999-9999-999999999999",
                  "kind": "movie",
                  "title": "Signal in the Static",
                  "parentEntityId": null,
                  "sortOrder": null,
                  "hasSourceMedia": true,
                  "capabilities": [
                    { "kind": "description", "value": "A patient, atmospheric mystery about a signal that should not exist and the people compelled to follow it." },
                    { "kind": "rating", "value": 4 },
                    { "kind": "flags", "isFavorite": true, "isNsfw": false, "isOrganized": true, "isWanted": false },
                    { "kind": "dates", "items": [{ "code": "released", "value": "2025-10-17" }] },
                    { "kind": "stats", "items": [{ "code": "budget", "value": 42000000 }, { "code": "revenue", "value": 138000000 }] },
                    { "kind": "position", "items": [{ "code": "part", "value": 1, "label": "Part One" }] },
                    { "kind": "classification", "value": "Feature", "system": "Prismedia" },
                    { "kind": "links", "urls": [{ "value": "https://example.com/signal", "label": "Official Site" }], "externalIds": [{ "provider": "tmdb", "value": "603", "url": "https://www.themoviedb.org/movie/603" }] },
                    { "kind": "technical", "duration": "1h 52m", "width": 3840, "height": 2160, "codec": "hevc", "container": "mkv" }
                  ],
                  "childrenByKind": [
                    {
                      "kind": "video",
                      "label": "Related Videos",
                      "code": "related-videos",
                      "entities": [
                        {
                          "id": "11111111-1111-1111-1111-111111111111",
                          "kind": "video",
                          "title": "The Quiet Frequency",
                          "parentEntityId": "99999999-9999-9999-9999-999999999999",
                          "sortOrder": 1,
                          "hoverImages": [],
                          "meta": [{ "icon": "duration", "label": "48 min" }]
                        }
                      ]
                    }
                  ],
                  "relationships": [
                    {
                      "kind": "person",
                      "label": "Cast",
                      "code": "cast",
                      "entities": [
                        {
                          "id": "22222222-2222-2222-2222-222222222222",
                          "kind": "person",
                          "title": "Mara Voss",
                          "hoverImages": [],
                          "meta": []
                        }
                      ]
                    },
                    {
                      "kind": "tag",
                      "label": "Tags",
                      "code": "tags",
                      "entities": [
                        { "id": "44444444-4444-4444-4444-444444444444", "kind": "tag", "title": "Atmospheric", "hoverImages": [], "meta": [] },
                        { "id": "55555555-5555-5555-5555-555555555555", "kind": "tag", "title": "Science Fiction", "hoverImages": [], "meta": [] },
                        { "id": "66666666-6666-6666-6666-666666666666", "kind": "tag", "title": "Mystery", "hoverImages": [], "meta": [] }
                      ]
                    },
                    {
                      "kind": "studio",
                      "label": "Studio",
                      "code": "studio",
                      "entities": [
                        { "id": "77777777-7777-7777-7777-777777777777", "kind": "studio", "title": "Northlight Pictures", "hoverImages": [], "meta": [] }
                      ]
                    }
                  ],
                  "creditMetadata": [
                    { "personId": "22222222-2222-2222-2222-222222222222", "role": "actor", "character": "Dr. Hale", "roles": ["actor", "producer"], "characters": ["Dr. Hale"] }
                  ]
                }
                """
            return try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
        }()
    }

#endif
