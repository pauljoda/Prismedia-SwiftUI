"""Render Swift Entity-kind definitions from Prismedia's backend code manifest."""

from __future__ import annotations

import json
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = (
    REPOSITORY_ROOT
    / "PrismediaShared/Domain/Entities/Generated/EntityKindDefinitions.generated.swift"
)


def swift_literal(value: str) -> str:
    """Encode the manifest's ASCII contract text as a Swift string literal."""
    return json.dumps(value, ensure_ascii=False)


def swift_member(name: str) -> str:
    return name[:1].lower() + name[1:]


def swift_bool(value: bool) -> str:
    return "true" if value else "false"


def render_extension(type_name: str, entries: list[dict]) -> str:
    declarations = "\n".join(
        f"    static let {swift_member(entry['name'])} = Self(rawValue: {swift_literal(entry['code'])})"
        for entry in entries
    )
    return f"public extension {type_name} {{\n{declarations}\n}}"


def render_manifest(manifest: dict) -> str:
    enums = manifest["enums"]
    entity_kinds = manifest["entityKinds"]
    accent_indexes = {
        entry["code"]: index
        for index, entry in enumerate(enums["EntityAccentHue"])
    }

    sections = [
        "// AUTO-GENERATED from Prismedia's backend EntityKind definitions.",
        "// Do not edit by hand. Run `python3 Scripts/generate-entity-kind-definitions.py`.",
        "",
        "import Foundation",
        "",
        render_extension("EntityKind", enums["EntityKind"]),
        "",
        render_extension("EntityKindIcon", enums["EntityKindIcon"]),
        "",
        render_extension("EntityAccentHue", enums["EntityAccentHue"]),
        "",
        render_extension("EntityArtworkFit", enums["EntityArtworkFit"]),
        "",
        "let generatedEntityKindDefinitions: [EntityKind: EntityKindDefinition] = [",
    ]

    for kind in entity_kinds:
        kind_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityKind"]
            if entry["code"] == kind["code"]
        ))
        icon_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityKindIcon"]
            if entry["code"] == kind["icon"]
        ))
        reference_icon_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityKindIcon"]
            if entry["code"] == kind["referenceIcon"]
        ))
        fit_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityArtworkFit"]
            if entry["code"] == kind["artworkFit"]
        ))
        primary_hue_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityAccentHue"]
            if entry["code"] == kind["primaryAccent"]
        ))
        secondary_hue_member = swift_member(next(
            entry["name"]
            for entry in enums["EntityAccentHue"]
            if entry["code"] == kind["secondaryAccent"]
        ))

        sections.extend([
            f"    .{kind_member}: EntityKindDefinition(",
            f"        kind: .{kind_member},",
            f"        displayName: {swift_literal(kind['displayName'])},",
            f"        groupLabel: {swift_literal(kind['groupLabel'])},",
            f"        category: {swift_literal(kind['category'])},",
            f"        storageShape: {swift_literal(kind['storageShape'])},",
            "        presentation: EntityKindPresentation(",
            f"            icon: .{icon_member},",
            f"            referenceIcon: .{reference_icon_member},",
            f"            thumbnailWidth: {kind['thumbnailWidth']},",
            f"            thumbnailHeight: {kind['thumbnailHeight']},",
            f"            primaryAccent: .{primary_hue_member},",
            f"            secondaryAccent: .{secondary_hue_member},",
            f"            primaryAccentIndex: {accent_indexes[kind['primaryAccent']]},",
            f"            secondaryAccentIndex: {accent_indexes[kind['secondaryAccent']]},",
            f"            artworkFit: .{fit_member}",
            "        ),",
            f"        supportsFileDeletion: {swift_bool(kind['supportsFileDeletion'])},",
            f"        supportsRequests: {swift_bool(kind['supportsRequests'])},",
            f"        enumeratesIdentifyChildren: {swift_bool(kind['enumeratesIdentifyChildren'])}",
            "    ),",
        ])

    sections.extend([
        "]",
        "",
    ])
    return "\n".join(sections)
