# Request, Identify, and Jobs Mobile Parity

This map records the mobile web hierarchy that the SwiftUI surfaces mirror. The native app keeps the same ordering, scoping, and disclosure behavior while using SwiftUI controls and platform navigation.

## Request

| Mobile web block | Native SwiftUI equivalent |
| --- | --- |
| Discover, Downloads, Missing, Cutoff, History tabs | iOS: navigation-title menu; macOS: segmented `Picker` in the toolbar |
| Content-kind toggle chips | Menu-style `Picker` row at the top of the Search section |
| Provider search fields | Native styled `TextField` controls in the Search section |
| Candidate cards (poster · title/year · Best badge · overview) | `PluginCandidateCard` with preview-sized provider artwork and a "No provider description available." fallback |
| Load more paging (25 → 100) | `Load More` row that grows the search `limit` |
| Status, kind, and sort dropdowns | Inline menu-style `Picker` controls in a Filters section |
| Proposal context bar (poster, kind badge, `namespace:value`) | `MetadataProposalHeaderView` |
| Metadata and related metadata accordions with counts | `DisclosureGroup` sections with field/item counts and All/None controls |
| "Request this …" card (monitor preset, quality profile, import destination, submit) | Single request panel combining the preset picker, `RequestTargetOptionsView`, and the commit button |

Provider artwork previews are right-sized through `ProviderImagePreviewPolicy`
(TMDB size-path rewriting and googleusercontent size hints), matching the web
preview policy so full-resolution originals are only fetched when applied.

## Identify

The series path was inspected with live rich data because it exercises fields, credits, relationships, artwork, seasons, and episodes. The reference path was MythBusters → Specials → Best Animal Myths, plus the Discovery studio relationship.

| Mobile web block or behavior | Native SwiftUI equivalent |
| --- | --- |
| Dashboard and entity-kind tabs with pending counts | Dashboard with push navigation into each kind (no duplicate scope rail on iPhone) |
| Browse-by-kind cards | Two-column native `NavigationLink` grid with kind, queue count, and accent highlight when queued |
| Dashboard review-queue rows | Inline queue section on the dashboard with per-row navigation and a link to the full selectable queue |
| "To Identify" target preview | `IdentifyTargetContextBar` above the search and proposal surfaces |
| Unorganized/All and provider filters | Segmented and menu-style `Picker` controls above results |
| Root proposal sections | Shared proposal review with native disclosures |
| Credits, relationships, and children | Selectable disclosure rows with a separate full-width navigation target |
| Child or relationship drill-down | The same review surface, recursively scoped to the selected proposal |
| Parent and sibling traversal | Native parent button and previous/next controls above the scoped review |
| Selection across recursive scopes | One root review selection keyed by proposal ID |

Sibling navigation remains within the current branch: relationships traverse adjacent relationships, while structural children traverse adjacent children. Every branch can continue recursively through the same scoped review surface.

## Jobs

| Mobile web block | Native SwiftUI equivalent |
| --- | --- |
| Active, queued, and failed summary | Status section with live counts |
| Clear failures, kill all, and refresh | Native action buttons in the status section |
| Scan and maintenance switchboard | Catalog rows with run, stop, and clear controls |
| Active, queued, failed, and completed job groups | Type-grouped `DisclosureGroup` sections |
| Run progress and diagnostic output | Native progress view and expandable run details |

Worker health and schedule details are not shown yet because the current native administration service does not expose those web contracts. The native screen does not fabricate placeholder state for them.
