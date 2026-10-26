# Moving malachite to LineageOS 24.0 (Android 17)

**Status: source port only. Nothing here has been built as a ROM, booted or
tested on a phone.** The `lineage-23.2` branches and the evidence under
[candidates](candidates) are unchanged.

Upstream base: LineageOS `lineage-24.0` (AOSP `android-17.0.0_r1`, release
config `cp2a`). Every fork's own commits were replayed onto the upstream
`lineage-24.0` branch of its source instead of merging 24.0 into the 23.2
history. Commits picked from 23.2 carry a `(cherry picked from commit …)`
line; where a commit needed adapting, its message says what changed and why.

## Per repository

| Repository | Result on 24.0 |
| --- | --- |
| device tree | Manifest, README and workflows moved to `lineage-24.0`; see below |
| frameworks/base | 15 commits ported: FaceSense, three-finger screenshot, market name, backlight precision, voice volume index, screenshot flash, QS pulldown. Two change/revert pairs from 23.2 dropped as no-ops. FaceSense matches PixelOS's `seventeen` apart from its later private-space change, which also needs a ParanoidSense change we don't carry |
| frameworks/native | ProducerListener ABI shim reworked (see below); the four GED KPI commits applied as one change with the same result; Dolby Vision HDR capability unchanged |
| packages/apps/Settings | eSIM slot selection, three-finger screenshot switch, refresh-rate floor: conflicts with new upstream code resolved |
| packages/services/Telephony | Both commits applied cleanly |
| external/wpa_supplicant_8 | WPA3 opt-in moved into upstream's new `wpa_ver_supported()`; `tests/wpa_version_3` updated and passing |
| hardware/mediatek | Codec2 AIDL, memtrack hardening and the mt66xx driver-command library replayed; BT-audio interfaces, dummy `libaedv` and `aee_modem_warning()` dropped because upstream now has them; `tests/` passing |
| hardware/xiaomi | All six commits applied cleanly |
| device/mediatek/sepolicy_vndr | Six labels and rules replayed, no duplicates of upstream's |
| packages/modules/Bluetooth | Fork dropped: LineageOS change 507009 is merged in `lineage-24.0` |
| vendor/xiaomi/malachite | `libformatter` and `libmnl` renamed (below); no other blob changed |
| malachite-kernel, vendor/mediatek/ims, ParanoidSense, hardware/dolby | Content unchanged, branch renamed only |
| kernel workspace (kernel_manifest-6.1 and its four projects) | Unchanged; it is pinned separately and does not depend on the Android version |

## Android 17 changes the device tree needed

- **libgui ABI shim.** `ProducerListener::onBufferDetached` now takes
  `(int slot, uint64_t bufferId)`. Re-declaring the old `onBufferDetached(int)`
  in `BnProducerListener` would hide the new overload, which breaks
  `BnProducerListener::onTransact()` and trips `-Woverloaded-virtual` in
  subclasses. The old symbol is now exported from a free function with its
  mangled name.
- **Blob names.** Android 17 adds `external/libmnl` (netlink `libmnl`).
  MediaTek's GNSS `libmnl` is now `libmnl_mtk`, and `mnld` links to it.
  `libformatter` (needed by the Codec2 venc/vdec blobs) becomes
  `libformatter_mtk`, as LineageOS devices did on 24.0 to avoid a Car library
  of that name. The Car, SDV, `hardware/interfaces` and Lineage car sources
  checked here define no `libformatter`, so for that one the rename is only a
  precaution. Blobs were patched with patchelf 0.18 (extract-utils' default).
  The vendor makefiles were regenerated with lineage-24.0 extract-utils; the
  only differences are these renames.
- **SELinux.** sepolicy_vndr 24.0 labels nine sysfs wakeup paths and the
  MediaTek Bluetooth audio provider service that the device tree also
  labelled. A second `genfscon` for the same path is a checkpolicy error, and
  a second, different service label fails `service_contexts`. The device
  entries were removed. Upstream's `hal_audio_service` lets the audio HAL
  register the service, and audio clients and the Bluetooth stack look it up.
- **Soong namespaces.** lineage-24.0 splits `hardware/google/pixel` into
  `health`, `pixelstats`, `power-libperfmgr`, `thermal` and `usb` namespaces.
  The thermal HAL and `thermal_symlinks` now live in `thermal`. The power HAL
  installs `libperfmgr` from `power-libperfmgr`, and the thermal HAL installs
  `libpixelstats` and `pixelatoms-cpp` from `pixelstats`. Those three are now in
  `PRODUCT_SOONG_NAMESPACES`; `usb` only provides a static library to
  hardware/mediatek, which imports it. hardware/mediatek also folded its
  `libaedv` namespace into the main one, so `hardware/mediatek/libaedv` was
  removed from `PRODUCT_SOONG_NAMESPACES` and from the vendor namespace imports
  (`extract-files.py`, regenerated `Android.bp`); a namespace that no longer
  exists stops Soong.
- **Build variables.** vendor/lineage adds `fastbootd` itself, and removed
  `TARGET_KERNEL_NO_GCC` (kernels always build with LLVM now); both lines were
  dropped.

## Checked without a change

- VINTF `target-level="7"` is still supported (Lineage moved level-6 devices
  to 7 for 24.0).
- `GraphicBuffer`'s layout is unchanged, so `blob_fixups_camera.py`'s `0xd30`
  size still holds (header comparison, not a measured `sizeof`).
- `hardware/google/pixel`'s ADPF parser (`HintManager.cc`) is byte-identical,
  so `powerhint.json` stays valid.
- Vendor prebuilts named like hardware/mediatek modules (`wlan_assistant`,
  Codec2 store, `libladder`, `netdagent`) are `prefer: true` in a namespace that
  imports hardware/mediatek, so the prebuilt replaces the source module.
- `libprotobuf-cpp-full-21.7` resolves the same way as on 23.2. Only the
  platform's 4.25.8 copy moved to vendorcompat, and malachite does not use it.

## Evidence

| Check | Result |
| --- | --- |
| Device tree `python3 -m unittest discover -s tests` | 192 run, 0 failures, 1 skip (needs stock `MiCamCPUControl.xml`); with sepolicy_vndr, hardware/mediatek and hardware/dolby beside the tree |
| vendor tree tests | 8 run, OK |
| wpa_supplicant `tests/wpa_version_3/run.sh` | all cases PASS |
| hardware/mediatek `tests/` | 2 run, OK |
| Monolithic SELinux policy, lineage-24.0 `system/sepolicy` + `device/lineage/sepolicy` + `device/generic/trusty` (`android-17.0.0_r1`) + sepolicy_vndr + device policy, m4 as `se_policy_conf`, AOSP `checkpolicy` from lineage-24.0 `external/selinux`, neverallows on | user and userdebug compile; before the genfs fix: duplicate-entry error. The same build of the 23.2 inputs also compiles. Release flags all set to true, `target_board_api_level=202604` |
| `libgui` shim | compiled in isolation with clang `-Wall -Wextra -Werror`; exported symbol demangles to `android::BnProducerListener::onBufferDetached(int)` |

Not done: a full `m bacon`, VINTF/ELF checks on built images, and any
device test. Expect the first full build to find more. The usual places are
framework code in the ported commits (only checked by reading 24.0's APIs),
the blobs' system-library ABI (`system_ext`/`product` blobs against Android
17's libraries), and new Android 17 sepolicy that only the full split build
checks.
