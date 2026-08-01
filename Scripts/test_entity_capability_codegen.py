#!/usr/bin/env python3
"""Regression tests for generated native Entity capability decoding."""

from __future__ import annotations

import unittest
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))

from entity_capability_codegen import render_manifest


class EntityCapabilityCodegenTests(unittest.TestCase):
    def test_manifest_drives_cases_decoding_kind_and_payload_access(self) -> None:
        rendered = render_manifest({"capabilityKinds": ["description", "dates"]})

        self.assertIn("case description(EntityDescriptionCapability)", rendered)
        self.assertIn("case dates(EntityItemsCapability<EntityDate>)", rendered)
        self.assertIn(
            "case .description: self = .description(try EntityDescriptionCapability(from: decoder))",
            rendered,
        )
        self.assertIn("case .dates(let value): value", rendered)
        self.assertIn("case .unknown(let value): EntityCapabilityKind(rawValue: value.kind)", rendered)

    def test_unknown_backend_capability_requires_one_native_payload_registration(self) -> None:
        with self.assertRaisesRegex(ValueError, "No native payload type registered"):
            render_manifest({"capabilityKinds": ["future-capability"]})


if __name__ == "__main__":
    unittest.main()
