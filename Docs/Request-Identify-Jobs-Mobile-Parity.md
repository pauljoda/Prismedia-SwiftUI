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

## Entity Acquisition

The entity detail Acquisition tab mirrors the web `EntityAcquisitionCard` + `AcquisitionPanel` pair for leaf entities. Child monitoring and book rendition rows are not ported yet.

| Web block | Native SwiftUI equivalent |
| --- | --- |
| Monitor toggle with state labels (Monitoring / Resume monitoring / Monitor / Finish unmonitoring / Deleting files… / Updating…) | `PrismediaButton` monitor toggle in `EntityAcquisitionPanel` with the same labels; unmonitor keeps a native destructive confirmation dialog |
| "Search for release" for a wanted item with no acquisition, plus its hint line | Prominent "Search for release" button gated on `canRequest` and no latest acquisition, committing via `POST /api/requests/commit-entity` |
| Monitor tracked-via line ("Monitoring via …", "Monitoring available — tracked via …") | Caption guidance line under the action row |
| Acquisition status badge + inline actions (Retry import / Import anyway, Start over with confirmation, Search again, Cancel) | Embedded `RequestActivityAcquisitionManagementSections` (`.embedded` style) status header with the same actions on iOS and macOS |
| Searching-indexers and cleanup placeholders | `RequestActivityStatePlaceholder` busy placeholders |
| Download section (stage label, percent, progress bar, Speed / ETA / Seeds ÷ Peers / Size stats) | `RequestActivityDownloadSection` fed by the transfer probe |
| Collapsible Files list that collapses once imported | `RequestActivityFilesSection` `DisclosureGroup` with collapse-once-imported behavior |
| Releases section (count header, "No releases found", Download / Download anyway with the manual-queue rejection ban, Blocklist) | `RequestActivityReleasesSection` with `RequestActivityCandidateRow` in its `.download` variant and `RequestActivityReleasePolicy` |
| "Have a .torrent file?" manual upload fallback | Upload panel driving the shared `.fileImporter` torrent flow |
| Collapsible History section (event badge, release/quality/indexer, relative time) | `EntityAcquisitionHistorySection` fed by `GET /api/acquisitions/history?entityId=` (limit 50) |
| Polling (panel 3s while active; entity state 5s) | Shared `.task(id:)` + sleep polling at 4s for both the panel state and the embedded acquisition sections |

tvOS keeps the simpler monitor/latest-acquisition summary with Search Again; the embedded management surface is iOS/macOS only, matching the request-activity feature gating.

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
