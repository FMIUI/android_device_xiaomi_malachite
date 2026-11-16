# POCO X7 / Redmi Note 14 Pro 5G (malachite) on CLO-based ROMs

Branch `clo` of this device tree, for PenguinOS celerity (Android 17, AOSPA/CLO base).
Tested: boots, Wi-Fi (2.4/5 GHz), mobile data, calls, Bluetooth, Dolby, Malachite Parts, CIT, recovery with sideload.

## 1. Sync
Install git-lfs first (the vendor blobs use LFS).

    repo init -u https://github.com/Project-PenguinOS/manifest -b celerity --git-lfs
    mkdir -p .repo/local_manifests
    curl -L https://raw.githubusercontent.com/FMIUI/android_device_xiaomi_malachite/clo/penguin.xml -o .repo/local_manifests/malachite.xml
    repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all)

## 2. Keys (once)

    bash device/xiaomi/malachite/tools/make-keys.sh vendor/aospa-priv/keys "/C=XX/ST=State/L=City/O=YourName/OU=YourName/CN=YourName/emailAddress=you@example.com"

Back up vendor/aospa-priv/keys somewhere private. Every future build must use the same keys.

## 3. Build
Use a persistent session (byobu/tmux) on shared servers.

    ./rom-build.sh malachite -t user -g -j$(nproc --all)
    bash device/xiaomi/malachite/tools/make-keys.sh vendor/aospa-priv/keys "<same subject>"
    ./rom-build.sh malachite -t user -g -s vendor/aospa-priv/keys -j$(nproc --all)

The first build is unsigned; running make-keys.sh again then creates the APEX keys; the third command makes the signed (release-keys) build.
The signed zip is written to the source root (PenguinOS-...-malachite.zip), next to ...-signed-target_files.zip.
"Error: No beans found for the device (malachite)" is harmless (malachite is not an official PenguinOS device).
Maintainer name: edit overlay-penguin/SettingsPenguinOverlayMalachite/res/values/strings.xml.

## 4. Flash (clean)
Boot images: IMAGES/boot.img and IMAGES/vendor_boot.img from the signed target-files zip.

    fastboot flash boot boot.img
    fastboot flash vendor_boot vendor_boot.img
    fastboot reboot

Hold Volume Up while it reboots to enter recovery ("fastboot reboot recovery" loops on malachite).
Recovery: Apply update > Apply from ADB, adb sideload <zip>, then Factory reset > Format data, Reboot system.
Builds signed with the same keys can be dirty-flashed over each other.

## What this tree handles for CLO
- No Qualcomm common components (TARGET_COMMON_QTI_COMPONENTS empty); Qualcomm-only repos left out of the scan (PRODUCT_SOURCE_ROOT_DIRS).
- patches/apply-core.sh (runs on every build): stand-ins for Lineage-only modules (org.lineageos.settings.resources, generated_kernel_headers, qti_kernel_headers), MediaTek powercap genfs vs Android 17 labels, and LineageOS's generic DRM backend for the recovery (AOSPA's recovery display code is Qualcomm SDE-only and draws nothing on MediaTek).
- SELinux sepolicy/vendor/aospa_compat.te: Qualcomm sysfs labels used by AOSPA, Lineage touch HAL policy, CLO wpa_supplicant ISupplicantVendor label (Wi-Fi), powercap access; power HAL (libperfmgr) file label; sepolicy/private/qti_stubs.te silences lookups for Qualcomm-only services.
- configs/vintf/framework_compatibility_matrix_aospa.xml: Lineage touch and QTI supplicant HALs.
- Malachite Parts, CIT, Goodix test via vendor/malachite-extras (run: bash vendor/malachite-extras/check.sh after a build).

## Notes
- Blur: enable "full COS experience" in Settings.
- vbmeta is signed with the AOSP AVB test key (fine with an unlocked bootloader).
- Boot patch level follows PenguinOS's release; always format data when coming from another ROM.
