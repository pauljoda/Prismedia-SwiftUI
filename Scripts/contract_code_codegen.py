"""Render Swift wire-code constants from Prismedia's backend code manifest."""

from __future__ import annotations

import json
import re
from pathlib import Path


REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
OUTPUT = (
    REPOSITORY_ROOT
    / "PrismediaShared/Domain/Entities/Generated/ContractCodes.generated.swift"
)

# Native RawRepresentable wrappers intentionally stay forward compatible. Their known values are
# emitted here so the backend manifest, rather than each wrapper file, owns the closed vocabulary.
NATIVE_ENUM_TYPES = {
    "AcquisitionStatus": "AcquisitionStatus",
    "BookActivityKind": "BookActivityKind",
    "BookFormat": "BookFormat",
    "BookRendition": "RequestActivityBookRendition",
    "BlocklistReason": "RequestActivityBlocklistReason",
    "DownloadProtocol": "RequestActivityDownloadProtocol",
    "EntityEngagementMode": "EntityEngagementMode",
    "MonitorStatus": "EntityMonitorStatus",
    "PlaybackEventKind": "PlaybackEventKind",
    "ProgressUnit": "ProgressUnit",
    "ProposalKind": "ProposalKind",
    "ReaderMode": "ReaderMode",
    "ReleaseRejectionReason": "RequestActivityReleaseRejection",
    "AcquisitionHistoryEvent": "RequestActivityHistoryEvent",
    "UserRole": "UserRole",
}


def swift_literal(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def swift_member(name: str) -> str:
    return name[:1].lower() + name[1:]


def code_member(code: str) -> str:
    parts = [part for part in re.split(r"[^A-Za-z0-9]+", code) if part]
    if not parts:
        raise ValueError(f"Cannot derive a Swift member from code {code!r}")
    return parts[0].lower() + "".join(part[:1].upper() + part[1:] for part in parts[1:])


def escaped(identifier: str) -> str:
    return f"`{identifier}`"


def enum_entries(manifest: dict, enum_name: str) -> list[tuple[str, str]]:
    return [
        (swift_member(entry["name"]), entry["code"])
        for entry in manifest["enums"][enum_name]
    ]


def namespace(name: str, entries: list[tuple[str, str]]) -> list[str]:
    return [
        f"    public enum {name} {{",
        *[
            f"        public static let {escaped(member)} = {swift_literal(code)}"
            for member, code in entries
        ],
        "    }",
    ]


def wrapper_extension(
    swift_type: str,
    namespace_name: str,
    entries: list[tuple[str, str]],
) -> list[str]:
    return [
        f"public extension {swift_type} {{",
        *[
            f"    static let {escaped(member)} = Self(rawValue: "
            f"PrismediaContractCodes.{namespace_name}.{escaped(member)})"
            for member, _ in entries
        ],
        "}",
    ]


def render_manifest(manifest: dict) -> str:
    enums = manifest["enums"]
    families: list[tuple[str, list[tuple[str, str]]]] = [
        (enum_name, enum_entries(manifest, enum_name))
        for enum_name in sorted(enums)
    ]
    families.extend([
        (
            "CapabilityKind",
            [(code_member(code), code) for code in manifest.get("capabilityKinds", [])],
        ),
        (
            "ExternalIDProvider",
            [
                (swift_member(entry["name"]), entry["value"])
                for entry in manifest.get("externalIdProviders", [])
            ],
        ),
        (
            "ProblemCode",
            [
                (swift_member(entry["name"]), entry["value"])
                for entry in manifest.get("problemCodes", [])
            ],
        ),
        (
            "SettingKey",
            [
                (swift_member(entry["name"]), entry["value"])
                for entry in manifest.get("settingKeys", [])
            ],
        ),
        (
            "ThumbnailMetaIcon",
            [
                (swift_member(entry["name"]), entry["value"])
                for entry in manifest.get("thumbnailMetaIcons", [])
            ],
        ),
    ])

    duplicate_names = [
        name
        for name, count in {
            name: sum(1 for candidate, _ in families if candidate == name)
            for name, _ in families
        }.items()
        if count > 1
    ]
    if duplicate_names:
        raise ValueError(f"Duplicate generated Swift code families: {duplicate_names}")

    sections = [
        "// AUTO-GENERATED from Prismedia's backend code-registry manifest.",
        "// Do not edit by hand. Run `python3 Scripts/generate-contract-codes.py`.",
        "",
        "import Foundation",
        "",
        "/// Complete generated snapshot of backend closed-set wire identifiers.",
        "public enum PrismediaContractCodes {",
    ]
    for name, entries in families:
        sections.extend(namespace(name, entries))
        sections.append("")
    sections[-1] = "}"

    for enum_name, swift_type in NATIVE_ENUM_TYPES.items():
        entries = enum_entries(manifest, enum_name)
        sections.extend(["", *wrapper_extension(swift_type, enum_name, entries)])

    capability_entries = [
        (code_member(code), code)
        for code in manifest.get("capabilityKinds", [])
    ]
    sections.extend([
        "",
        *wrapper_extension("EntityCapabilityKind", "CapabilityKind", capability_entries),
        "",
    ])
    return "\n".join(sections)
