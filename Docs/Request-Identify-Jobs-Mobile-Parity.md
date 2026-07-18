# Request, Identify, and Jobs Mobile Parity

This map records the mobile web hierarchy that the SwiftUI surfaces mirror. The native app keeps the same ordering, scoping, and disclosure behavior while using SwiftUI controls and platform navigation.

## Request

| Mobile web block | Native SwiftUI equivalent |
| --- | --- |
| Discover, Downloads, Missing, Cutoff, History tabs | Visible segmented `Picker` rail |
| Content-kind dropdown | Menu-style `Picker` beside the rail |
| Provider search fields | Native styled `TextField` controls in the Search section |
| Status, kind, and sort dropdowns | Inline menu-style `Picker` controls in a Filters section |
| Metadata and related metadata accordions | `DisclosureGroup` sections in proposal review |
| Quality profile and import destination dropdowns | Native menu-style `Picker` controls in the request action section |

## Identify

The series path was inspected with live rich data because it exercises fields, credits, relationships, artwork, seasons, and episodes. The reference path was MythBusters → Specials → Best Animal Myths, plus the Discovery studio relationship.

| Mobile web block or behavior | Native SwiftUI equivalent |
| --- | --- |
| Dashboard and entity-kind tabs | Visible segmented `Picker` rail |
| Browse-by-kind cards | Two-column native button grid with kind and queue count |
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
