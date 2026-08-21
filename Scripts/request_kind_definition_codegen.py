"""Render Swift request-kind definitions from Prismedia's backend code manifest."""

from __future__ import annotations

import json
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = REPOSITORY_ROOT / "PrismediaShared/Features/Request/Models/RequestKindDefinition.swift"


def literal(value: str | None) -> str:
    return "nil" if value is None else json.dumps(value, ensure_ascii=False)


def member(code: str) -> str:
    parts = code.split("-")
    return parts[0] + "".join(part.capitalize() for part in parts[1:])


def review_mode(code: str) -> str:
    return {
        "root": ".root",
        "direct-children": ".directChildren",
        "direct-children-when-present": ".directChildrenWhenPresent",
    }[code]


def render_manifest(manifest: dict) -> str:
    kinds = manifest["requestKinds"]
    entity_members = {entry["code"]: member(entry["code"]) for entry in manifest["enums"]["EntityKind"]}
    cases = "\n".join(
        f"    case {member(entry['kind'])}"
        + (f" = {literal(entry['kind'])}" if member(entry["kind"]) != entry["kind"] else "")
        for entry in kinds
    )

    def request_member(entry: dict) -> str:
        return member(entry["kind"])

    def property(name: str, body: list[str], type_name: str) -> str:
        return "\n".join([
            f"    public var {name}: {type_name} {{",
            "        switch self {",
            *body,
            "        }",
            "    }",
        ])

    sections = [
        "// AUTO-GENERATED from Prismedia's backend request-kind manifest.",
        "// Do not edit by hand. Run `python3 Scripts/generate-request-kind-definitions.py`.",
        "",
        "import Foundation",
        "",
        "public enum RequestKindDefinition: String, CaseIterable, Identifiable, Hashable, Sendable {",
        cases,
        "",
        "    public var id: String { rawValue }",
        "",
        property("label", [f"        case .{request_member(x)}: {literal(x['label'])}" for x in kinds], "String"),
        "",
        property("pluralLabel", [f"        case .{request_member(x)}: {literal(x['plural'])}" for x in kinds], "String"),
        "",
        property("childNoun", [f"        case .{request_member(x)}: return {literal(x['childNoun'])}" for x in kinds], "String?"),
        "",
        property("entityKind", [f"        case .{request_member(x)}: return .{entity_members[x['entityKind']]}" for x in kinds], "EntityKind"),
        "",
        property("pluginEntityKind", [f"        case .{request_member(x)}: {literal(x['pluginEntityKind'])}" for x in kinds], "String"),
        "",
        property("acquisitionKind", [f"        case .{request_member(x)}: return .{entity_members[x['acquisitionKind']]}" for x in kinds], "EntityKind"),
        "",
        property("profileKind", [f"        case .{request_member(x)}: return .{entity_members[x['profileKind']]}" for x in kinds], "EntityKind"),
        "",
        property("reviewSelection", [f"        case .{request_member(x)}: return {review_mode(x['reviewSelection'])}" for x in kinds], "RequestReviewSelectionMode"),
        "",
        property("isCommittable", [f"        case .{request_member(x)}: return {str(x['committable']).lower()}" for x in kinds], "Bool"),
        "",
        property("isDiscoverable", [f"        case .{request_member(x)}: return {str(x['discoverable']).lower()}" for x in kinds], "Bool"),
        "",
        "    public static var discoverable: [Self] { allCases.filter(\\.isDiscoverable) }",
        "",
        "    public func supports(root: AdministrativeLibraryRoot) -> Bool {",
        "        switch self {",
        *[f"        case .{request_member(x)}: return root.{x['rootFlag']}" for x in kinds],
        "        }",
        "    }",
        "}",
        "",
    ]
    return "\n".join(sections)
