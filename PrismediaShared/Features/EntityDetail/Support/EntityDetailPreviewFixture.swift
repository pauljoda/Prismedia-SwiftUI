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
                    }
                  ]
                }
                """
            return try! PrismediaJSON.decoder().decode(EntityDetail.self, from: Data(json.utf8))
        }()
    }

#endif
