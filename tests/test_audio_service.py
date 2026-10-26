"""Init service wiring regressions; hardware audio behavior needs device tests."""
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def audio_services():
    services = []
    for directory in (ROOT / "init", ROOT / "audio"):
        for path in sorted(directory.glob("*.rc")):
            current = None
            for line in path.read_text().splitlines():
                words = line.split("#", 1)[0].split()
                if not words:
                    continue
                if not line[0].isspace():
                    current = None
                    if words[:2] == ["service", "vendor.audio-hal"]:
                        current = {"path": path, "executable": words[2], "options": []}
                        services.append(current)
                elif current is not None:
                    current["options"].append(words)
    return services


class AudioServiceTests(unittest.TestCase):
    def test_audio_hal_has_one_definition_using_the_packaged_executable(self):
        services = audio_services()
        self.assertEqual(len(services), 1, services)
        self.assertEqual(services[0]["executable"],
                         "/vendor/bin/hw/android.hardware.audio.service.malachite")

    def test_replacement_retains_the_mediatek_audio_socket(self):
        replacement = [service for service in audio_services()
                       if service["executable"].endswith(".malachite")]
        self.assertEqual(len(replacement), 1)
        self.assertIn(["socket", "audio_hw_socket", "seqpacket", "0666", "system", "system"],
                      replacement[0]["options"])

    def test_loads_mediatek_bluetooth_audio_provider(self):
        # The MediaTek provider shares its session library with stock's Bluetooth HAL
        # and reaches the primary HAL in this process for offloaded A2DP.
        source = (ROOT / "audio/service.cpp").read_text()
        self.assertIn('"android.hardware.bluetooth.audio-impl-mediatek",', source)
        self.assertNotIn('"android.hardware.bluetooth.audio-impl",', source)
        device = (ROOT / "device.mk").read_text()
        self.assertNotRegex(device, r"(?m)^\s+android\.hardware\.bluetooth\.audio-impl\s")
        self.assertNotRegex(device, r"(?m)^\s+audio\.bluetooth\.default\b")
        blobs = (ROOT / "proprietary-files.txt").read_text().splitlines()
        for blob in ("vendor/lib64/android.hardware.bluetooth.audio-impl-mediatek.so",
                     "vendor/lib64/libbluetooth_audio_session_aidl_mtk.so",
                     "vendor/lib64/hw/audio.bluetooth.default.so:"
                     "vendor/lib64/hw/audio.bluetooth.mt6878.so;FIX_SONAME"):
            with self.subTest(blob=blob):
                self.assertIn(blob, blobs)

    def test_manifest_declares_the_provider_version(self):
        manifest = ET.parse(ROOT / "manifest.xml").getroot()
        hals = [hal for hal in manifest.iter("hal")
                if hal.findtext("name") == "android.hardware.bluetooth.audio"]
        self.assertEqual(len(hals), 1)
        self.assertEqual(hals[0].get("format"), "aidl")
        self.assertEqual(hals[0].findtext("version"), "3")
        self.assertEqual(hals[0].findtext("fqname"), "IBluetoothAudioProviderFactory/default")

    def test_provider_service_label_comes_from_sepolicy_vndr(self):
        # lineage-24.0's sepolicy_vndr labels the provider hal_audio_service. A second,
        # different label here makes the merged vendor service_contexts fail
        # ("Multiple different specifications").
        service = "vendor.mediatek.hardware.bluetooth.audio.IBluetoothAudioProviderFactory/default"
        self.assertNotIn(service, (ROOT / "sepolicy/vendor/service_contexts").read_text())
        policy = ROOT.parent / "device_mediatek_sepolicy_vndr" / "base" / "vendor"
        if not policy.is_dir():
            self.skipTest("device_mediatek_sepolicy_vndr is not checked out beside the tree")
        self.assertRegex((policy / "service_contexts").read_text(),
                         service.replace(".", r"\.") + r"\s+u:object_r:hal_audio_service:s0")

    def test_no_genfs_path_is_labeled_twice(self):
        # Duplicate genfscon entries are a checkpolicy error, even with the same label.
        policy = ROOT.parent / "device_mediatek_sepolicy_vndr" / "base" / "vendor"
        if not policy.is_dir():
            self.skipTest("device_mediatek_sepolicy_vndr is not checked out beside the tree")

        def paths(path):
            return {tuple(line.split()[1:3]) for line in path.read_text().splitlines()
                    if line.startswith("genfscon")}

        self.assertEqual(paths(ROOT / "sepolicy/vendor/genfs_contexts") &
                         paths(policy / "genfs_contexts"), set())


if __name__ == "__main__":
    unittest.main()
