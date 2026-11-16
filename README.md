# POCO X7 / Redmi Note 14 Pro 5G (malachite) — CLO-based ROMs

Device tree branch `clo`, for PenguinOS celerity (Android 17, QSSI 17, AOSPA/CLO base).
For the LineageOS-based tree (Shinkai and other Lineage ROMs), see branch `lineage-24.0`.

Device: Xiaomi malachite, MediaTek Dimensity 7300 (MT6878). Kernel: prebuilt (malachite-project).

**Tested:** boots (user, release-keys), Wi-Fi 2.4/5 GHz, mobile data, calls, Bluetooth, Dolby,
Malachite Parts, CIT, Goodix test, recovery with ADB sideload.

---

## Build

### 1. Sync
Install `git-lfs` first (the vendor blobs use LFS).

    repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs
    mkdir -p .repo/local_manifests
    curl -L https://raw.githubusercontent.com/FMIUI/android_device_xiaomi_malachite/clo/penguin.xml -o .repo/local_manifests/malachite.xml
    repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all)

### 2. Keys (once)

    bash device/xiaomi/malachite/tools/make-keys.sh vendor/aospa-priv/keys "/C=XX/ST=State/L=City/O=YourName/OU=YourName/CN=YourName/emailAddress=you@example.com"

Back up `vendor/aospa-priv/keys` somewhere private. Every future build must use the same keys.

### 3. Build
Use a persistent session (byobu/tmux) on shared servers.

    ./rom-build.sh malachite -t user -g -j$(nproc --all)
    bash device/xiaomi/malachite/tools/make-keys.sh vendor/aospa-priv/keys "<same subject>"
    ./rom-build.sh malachite -t user -g -s vendor/aospa-priv/keys -j$(nproc --all)

The first build is unsigned; running `make-keys.sh` again then creates the APEX keys; the third
command makes the signed (`release-keys`) build. The signed zip is written to the **source root**
(`PenguinOS-...-malachite.zip`), next to `...-signed-target_files.zip`.

- `Error: No beans found for the device (malachite)` is harmless (malachite is not an official PenguinOS device).
- Maintainer name: edit `overlay-penguin/SettingsPenguinOverlayMalachite/res/values/strings.xml`.
- After a build, `bash vendor/malachite-extras/check.sh` verifies Parts, CIT and the Goodix test.

### 4. Flash (clean)
Boot images: `IMAGES/boot.img` and `IMAGES/vendor_boot.img` from the signed target-files zip.

    fastboot flash boot boot.img
    fastboot flash vendor_boot vendor_boot.img
    fastboot reboot

Hold **Volume Up** while it reboots to enter recovery (`fastboot reboot recovery` loops on malachite).
Recovery: Apply update > Apply from ADB, `adb sideload <zip>`, then Factory reset > Format data, Reboot system.
Builds signed with the same keys can be dirty-flashed over each other.

### Notes
- Blur: enable "full COS experience" in Settings.
- `vbmeta` is signed with the AOSP AVB test key (fine with an unlocked bootloader).
- Boot patch level follows PenguinOS's release; always format data when coming from another ROM.

---

# Porting notes

How the `clo` branch was made from the LineageOS-based `lineage-24.0` tree: every change that was
needed, why, and the methods used to find each problem.

CLO/AOSPA trees are built for Qualcomm. A MediaTek device tree written for LineageOS meets three kinds
of mismatch:
1. **Lineage-only pieces** the tree relies on (modules, SELinux, build variables) that AOSPA lacks.
2. **Qualcomm-only pieces** in AOSPA that a MediaTek device must not build or install.
3. **Duplicates** where AOSPA already ships its own copy of something Lineage provided.

## 1. Product setup

| Change | Why |
|---|---|
| `aospa_malachite.mk` replaces the Lineage product file; `AndroidProducts.mk` points to it | AOSPA products are `aospa_<codename>`, built with `rom-build.sh <codename>` |
| `TARGET_BOARD_PLATFORM := mt6878` in `device.mk` | `device/qcom/common/common.mk` reads the platform during product config, before BoardConfig |
| `PRODUCT_COPY_FILES += device/xiaomi/malachite-kernel/Image.lz4:kernel` | AOSPA builds a kernel only when `TARGET_PREBUILT_KERNEL` is empty, but doesn't install a prebuilt one |
| `TARGET_COMMON_QTI_COMPONENTS :=` (empty) | Stops `device/qcom/common` from adding Qualcomm components (Adreno, DSP, QTI audio/BT/display/GPS) |
| Updater overlay removed | Shinkai's OTA updater overlay doesn't apply to PenguinOS |
| Signing keys in `vendor/aospa-priv/keys` (`keys.mk`: `PRODUCT_DEFAULT_DEV_CERTIFICATE`) | AOSPA's key location; see `tools/make-keys.sh` |
| `DEBUG-ADB` block (non-user builds only, local `adb_keys` never committed) | Pre-authorized ADB from first boot on userdebug, so a hang can be debugged with logcat |

Extra repos in the local manifest (`penguin.xml`), all from LineageOS:
`hardware/lineage/interfaces` (power libperfmgr, touch), `hardware/google/pixel`,
`device/lineage/sepolicy` (only its `libperfmgr` part is used, via MediaTek's sepolicy),
`packages/apps/EuiccPolicy` (eSIM policy, needed by Xiaomi's eSIM bundle).

## 2. Build-system stage (product config, Soong, kati)

| Symptom | Cause | Fix |
|---|---|---|
| `Error: No beans found for the device` | AOSPA's per-device repo list, only for official devices | Harmless; the local manifest does that job |
| `No release config set for target` | `lunch` was run inside a pipe, so its variables were lost | Run `lunch aospa_malachite-cp2a-<variant>` without a pipe |
| `vendor.lineage.health_interface already defined` | AOSPA ships its own copy of Lineage's health HAL (`vendor/aospa/interfaces/health`) | `PRODUCT_SOURCE_ROOT_DIRS += -hardware/lineage/interfaces/health` |
| `XiaomiEsimSwitcher` needs `org.lineageos.settings.resources` | Lineage renamed AOSPA's `co.aospa.resources` | Root-namespace alias library wrapping `co.aospa.resources` (generated by `patches/apply-core.sh` in `device/xiaomi/lineage-compat`) |
| `libcodec2_hidl_shim already defined by hardware/lineage/compat` | AOSPA's compat repo has the same objcpy bridge for old Codec2 blobs | Dropped the device tree's copy; the Dolby blob loads AOSPA's (same symbol) |
| `depends on undefined module "generated_kernel_headers"` | Lineage's kernel-header module; users are Qualcomm UDFPS code and MediaTek PowerOffAlarm (standard UAPI headers only) | Empty header-library stand-in (`apply-core.sh`) |
| `depends on undefined module "qti_kernel_headers"` | Qualcomm kernel headers, used by CLO's `tinycompress` | Stand-in (`apply-core.sh`); `tinycompress` is kept because MediaTek's audio HAL needs `libtinycompress` |
| Many Qualcomm modules with missing deps (display, GPS, data, IPA, thermal) | Qualcomm hardware repos in the CLO tree | Excluded via `PRODUCT_SOURCE_ROOT_DIRS` (`QCOM-EXCLUDES` in `device.mk`), plus `device/amlogic/yukawa` and `hardware/qcom/bootctrl`, which depend on them |
| `XiaomiEuicc requires non-existent EuiccPolicy` | Lineage's eSIM policy app | Added `packages/apps/EuiccPolicy` to the manifest |

Rule used for exclusions: a repo is only excluded if the product installs nothing from it **and**
nothing in the device's own repos depends on it (that check caught `tinycompress`).

## 3. Compile and packaging stage (SELinux, VINTF)

| Symptom | Cause | Fix |
|---|---|---|
| `unknown type vendor_sysfs_battery_supply` / `vendor_sysfs_usb_supply` | AOSPA's health HAL policy uses Qualcomm sysfs labels | Declared in `sepolicy/vendor/aospa_compat.te` |
| `unknown type hal_lineage_touch_default` | Touch HAL types come from Lineage's common policy, not used on AOSPA | Same declarations as Lineage (`hal_attribute(lineage_touch)`, service, domain, exec type) in `aospa_compat.te` + `service_contexts` |
| `Duplicate declaration of type` (`vendor_lmkd_prop`) | Already declared by MediaTek's policy through a macro | Removed the duplicate |
| `precompiled_sepolicy: Problems processing genfscon rules` | Android 17's platform genfs labels (202604) label `/sys/class/powercap` as `sysfs_powercap`; MediaTek labels it `sysfs_therm` | `apply-core.sh` drops MediaTek's two powercap genfs lines where the platform labels them; MediaTek's **vendor** domains get the same access to `sysfs_powercap` in `aospa_compat.te` |
| `files are incompatible`: `vendor.lineage.touch.IHighTouchPollingRate`, `vendor.qti.hardware.wifi.supplicant.ISupplicantVendor` not in framework matrix | Lineage's framework matrix lists them, AOSPA's doesn't | `configs/vintf/framework_compatibility_matrix_aospa.xml` via `DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE` |
| `check_vintf_system`: HIDL interfaces in `compatibility_matrix.6.xml` without definitions | AOSPA's own framework matrices | Not a device issue; only runs for `droid`, not for `rom-build.sh`'s `target-files-package` |

User builds: `permissive` domains are forbidden; MediaTek's `permissive osi` is inside
`userdebug_or_eng()`, so it's fine. The SELinux policy was checked under user rules before the first
user build (`lunch …-user`, then `m selinux_policy`).

## 4. Runtime (found by booting)

| Symptom | Cause | Fix |
|---|---|---|
| Stuck at boot animation, `watchdog` reboot, `system_server` restarting | `android.hardware.power-service.lineage-libperfmgr` labeled `vendor_file` (its label lives in Lineage's common policy), so init can't start it; `system_server` waits for `IPower` | `file_contexts` entry → `hal_power_default_exec` |
| Wi-Fi never turns on, `wpa_supplicant` exits with status 255 | CLO's `wpa_supplicant` also registers Qualcomm's `vendor.qti.hardware.wifi.supplicant.ISupplicantVendor`; unlabeled, servicemanager refuses it and the supplicant exits | `hal_wifi_supplicant_qti_service` type + `service_contexts` entry (`aospa_compat.te`) |
| Thousands of denials for `vendor.qti.hardware.servicetracker` and `vendor.perfservice` | AOSPA's framework looks up Qualcomm services that don't exist on MediaTek | Those names get their own label with `dontaudit` (`sepolicy/private/qti_stubs.te`); nothing else is hidden |
| No blur | Not a bug: PenguinOS ties blur to its "full COS experience" option | Enable it in Settings |
| "Unofficial build" in About phone | Maintainer comes from Settings string `penguin_maintainer` | Runtime resource overlay `overlay-penguin/SettingsPenguinOverlayMalachite` |

## 5. Recovery

**Symptom:** PenguinOS's recovery stays on the POCO logo at maximum brightness (HBM); Lineage-based
recoveries work.

**Cause:** AOSPA's `bootable/recovery/minui/graphics_drm.cpp` is written only for Qualcomm's SDE
display driver (topology, SPR/Demura properties, atomic commits). On MediaTek's DRM driver the panel
comes up but nothing is drawn. LineageOS keeps a generic DRM backend and the Qualcomm one separately
(`graphics_drm_qti.cpp`, behind `target_recovery_uses_qti_drm`).

**Fix:** `patches/recovery-minui/` holds LineageOS's generic `graphics_drm.cpp/.h`
(`lineage-24.0` @ `08054cf`, with the `PixelFormat::BGRX` branch removed because AOSPA's `minui.h`
lacks it; malachite uses `BGRA_8888`). `apply-core.sh` copies them over AOSPA's whenever they differ.

## 6. Signing

- `rom-build.sh -s <keydir>` signs with `sign_target_files_apks`; APEX keys are looked up per APEX as
  `<apex>.pk8/.x509.pem` (container) plus `<apex>.pem/.avbpubkey` (payload). The list comes from the
  build's `META/apexkeys.txt` (41 APEXes here). `tools/make-keys.sh` creates them.
- Result: `release-keys`, OTA verification key = `releasekey`, APEX modules signed with your own keys.
- The signed zip and `…-signed-target_files.zip` are written to the source root, not `out/`.
- `vbmeta` stays signed with AOSP's AVB test key (fine while the bootloader is unlocked).
- Builds signed with the same keys (including APEX keys) can be dirty-flashed over each other.

## 7. Methods used (how each problem was found)

Analyse before compiling:
- `m nothing`: runs product config, Soong and kati without compiling. Fast way to surface all
  build-system errors.
- `ALLOW_MISSING_DEPENDENCIES=true m nothing`, then search `out/soong/*.ninja*` for
  `missing dependencies:`: the complete list of missing modules in one pass, instead of one per run.
- For each missing module: find which repo uses it, and whether the product installs anything from
  that repo (`get_build_var PRODUCT_PACKAGES`), to decide between exclusion and a stand-in.

Collect every compile failure at once:
- `m -k otatools target-files-package check-vintf-all`: keeps going after failures;
  `out/error.log` lists every failed target.
- `m selinux_policy` (and `m -k selinux_policy`): checks SELinux in minutes instead of a full build.
- `secilc -v` on the failing command: names the exact genfscon conflict that `precompiled_sepolicy`
  only reports as "Problems processing genfscon rules".

Static checks of the built images:
- Every init service on vendor/odm/system_ext/product: its binary must resolve to an `*_exec` label
  (last matching rule across `plat`, `system_ext`, `product`, `vendor`, `odm` file_contexts, exact
  paths first) or have a `seclabel`. This found the power HAL label.
- Every AIDL/HIDL HAL in the vendor/odm manifests must have a `service_contexts`/`hwservice_contexts`
  entry.
- Boot images compared with a known-good build (Shinkai): kernel, DTB, `vendor_boot` header,
  cmdline, bootconfig, module list, fstab. Use the images in the target-files `IMAGES/`, which are
  what goes into the zip.
- Recovery fragment of `vendor_boot`: required binaries, every `NEEDED` library present, fstab.

On the device:
- DSU with the ROM's system **and** vendor images (userdebug) and `adb logcat -b all` recorded from
  boot until the watchdog reboot; the pre-authorized ADB key makes this possible on a hung boot.
- Reboot reason (`persist.sys.boot.reason.history`) and pstore after a failed boot.
- Comparing SELinux denials against the working ROM (Shinkai) to find only the new ones.
- `adb root; setenforce 0`: if a feature works in permissive mode, SELinux is the only blocker, and
  the log then shows **every** denial it needs, not only the first.

## 8. Commits

`git log --oneline lineage-24.0..clo` lists the changes in order; each message names the fix.
