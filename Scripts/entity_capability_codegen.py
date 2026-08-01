"""Render Swift Entity capability cases and decoding from Prismedia's manifest."""

from __future__ import annotations

from pathlib import Path

from contract_code_codegen import code_member


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = (
    REPOSITORY_ROOT
    / "PrismediaShared/Domain/Entities/Generated/EntityCapability.generated.swift"
)

# A capability's wire code comes from the backend. Its concrete Swift payload type is a native
# decoding concern, registered once here and expanded into the enum, decoder, discriminator, and
# generic payload accessor. Manifest parity makes an unregistered backend capability fail CI.
CAPABILITY_PAYLOAD_TYPES = {
    "book-metadata": "EntityBookMetadataCapability",
    "classification": "EntityClassificationCapability",
    "collection-configuration": "EntityCollectionConfigurationCapability",
    "cover-selection": "EntityCoverSelectionCapability",
    "credits": "EntityCreditsCapability",
    "dates": "EntityItemsCapability<EntityDate>",
    "description": "EntityDescriptionCapability",
    "embedded-audio-metadata": "EntityEmbeddedAudioMetadataCapability",
    "file-management": "EntityFileManagementCapability",
    "files": "EntityItemsCapability<EntityFile>",
    "fingerprints": "EntityItemsCapability<EntityFingerprint>",
    "flags": "EntityFlagsCapability",
    "gallery-metadata": "EntityGalleryMetadataCapability",
    "images": "EntityImagesCapability",
    "lifetime": "EntityLifetimeCapability",
    "links": "EntityLinksCapability",
    "markers": "EntityItemsCapability<EntityMarker>",
    "person-profile": "EntityPersonProfileCapability",
    "playable-video": "EntityPlayableVideoCapability",
    "playback": "EntityPlaybackCapability",
    "position": "EntityItemsCapability<EntityPosition>",
    "progress": "EntityProgressCapability",
    "provider-identity": "EntityProviderIdentityCapability",
    "rating": "EntityRatingCapability",
    "series-metadata": "EntitySeriesMetadataCapability",
    "source": "EntityItemsCapability<EntitySource>",
    "stats": "EntityItemsCapability<EntityStat>",
    "subtitles": "EntitySubtitlesCapability",
    "tag-policy": "EntityTagPolicyCapability",
    "technical": "EntityTechnicalCapability",
}


def capability_entries(manifest: dict) -> list[tuple[str, str, str]]:
    entries: list[tuple[str, str, str]] = []
    for code in manifest.get("capabilityKinds", []):
        payload_type = CAPABILITY_PAYLOAD_TYPES.get(code)
        if payload_type is None:
            raise ValueError(
                f"No native payload type registered for backend capability {code!r}"
            )
        entries.append((code_member(code), code, payload_type))
    return entries


def render_manifest(manifest: dict) -> str:
    entries = capability_entries(manifest)
    lines = [
        "// AUTO-GENERATED from Prismedia's backend capability manifest.",
        "// Do not edit by hand. Run `python3 Scripts/generate-entity-capabilities.py`.",
        "",
        "import Foundation",
        "",
        "/// Discriminated capability envelope. Unknown kinds remain available as raw",
        "/// JSON so a newer server does not make the entire detail document unreadable.",
        "public enum EntityCapability: Decodable, Hashable, Sendable {",
    ]
    lines.extend(
        f"    case {member}({payload_type})"
        for member, _, payload_type in entries
    )
    lines.extend([
        "    case unknown(UnknownEntityCapability)",
        "",
        "    private struct KindEnvelope: Decodable {",
        "        let kind: EntityCapabilityKind",
        "    }",
        "",
        "    public init(from decoder: Decoder) throws {",
        "        let kind = try KindEnvelope(from: decoder).kind",
        "",
        "        switch kind {",
    ])
    lines.extend(
        f"        case .{member}: self = .{member}(try {payload_type}(from: decoder))"
        for member, _, payload_type in entries
    )
    lines.extend([
        "        default: self = .unknown(try UnknownEntityCapability(from: decoder))",
        "        }",
        "    }",
        "",
        "    /// Manifest-backed discriminator for matching and mutation ownership.",
        "    public var kind: EntityCapabilityKind {",
        "        switch self {",
    ])
    lines.extend(
        f"        case .{member}: .{member}"
        for member, _, _ in entries
    )
    lines.extend([
        "        case .unknown(let value): EntityCapabilityKind(rawValue: value.kind)",
        "        }",
        "    }",
        "",
        "    /// Concrete payload used by EntityDetail's generic typed accessor.",
        "    public var payload: Any {",
        "        switch self {",
    ])
    lines.extend(
        f"        case .{member}(let value): value"
        for member, _, _ in entries
    )
    lines.extend([
        "        case .unknown(let value): value",
        "        }",
        "    }",
        "}",
        "",
    ])
    return "\n".join(lines)
