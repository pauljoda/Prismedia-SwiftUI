import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class VLCKitProfile5PatchTests(unittest.TestCase):
    def test_glsl100_reshape_patch_is_part_of_every_platform_build(self) -> None:
        bootstrap = (ROOT / "Scripts/bootstrap-vlckit.sh").read_text()
        binary_contract = (
            ROOT / "Scripts/vlckit-binary-contract.sh"
        ).read_text()
        profile5_patch = (
            ROOT / "Scripts/Patches/VLCKit4-DolbyVisionProfile5.patch"
        ).read_text()
        glsl_patch_path = (
            ROOT
            / "Scripts/Patches/VLCKit4-DolbyVisionProfile5-GLSL100.patch"
        )

        self.assertTrue(glsl_patch_path.exists())
        glsl_patch = glsl_patch_path.read_text()
        self.assertIn("sh_bvec(sh, 4)", glsl_patch)
        self.assertNotIn('++            GLSL("#define test(i) bvec4', glsl_patch)
        self.assertIn("GNU=https://ftp.gnu.org/gnu", glsl_patch)
        self.assertIn(glsl_patch_path.name, bootstrap)
        self.assertIn("vlckit-binary-contract.sh", bootstrap)
        self.assertIn("glsl100-dovi-reshape", binary_contract)
        self.assertIn("glsl100-dovi-reshape", profile5_patch)

    def test_adaptive_http_bearer_patch_is_part_of_every_platform_build(self) -> None:
        bootstrap = (ROOT / "Scripts/bootstrap-vlckit.sh").read_text()
        binary_contract = (
            ROOT / "Scripts/vlckit-binary-contract.sh"
        ).read_text()
        bearer_patch_path = (
            ROOT / "Scripts/Patches/VLCKit4-AdaptiveHTTPBearer.patch"
        )

        self.assertTrue(bearer_patch_path.exists())
        bearer_patch = bearer_patch_path.read_text()
        self.assertIn('var_InheritString(p_object_, "http-token")', bearer_patch)
        self.assertIn('"Authorization", "Bearer %s"', bearer_patch)
        self.assertIn("adaptive HTTP bearer forwarding enabled", bearer_patch)
        self.assertIn(bearer_patch_path.name, bootstrap)
        self.assertIn("vlckit-binary-contract.sh", bootstrap)
        self.assertIn(
            "adaptive HTTP bearer forwarding enabled", binary_contract
        )

if __name__ == "__main__":
    unittest.main()
