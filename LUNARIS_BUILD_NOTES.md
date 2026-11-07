# Lunaris A16 (16.2) build notes for malachite
- Use lunaris_local_manifest.xml as .repo/local_manifests/malachite.xml, then: repo sync -c -j4 --force-sync --no-tags
- If vendor/xiaomi/malachite fails with "missing protocol": git --git-dir=.repo/projects/vendor/xiaomi/malachite.git config lfs.url https://github.com/FMIUI/proprietary_vendor_xiaomi_malachite.git/info/lfs
- If vendor/pixel/* has no products/ dir: in each folder run git lfs fetch; git reset --hard HEAD; git lfs checkout
- Keys: create vendor/lineage-priv/keys (releasekey platform shared media networkstack verity otakey testkey sdk_sandbox bluetooth nfc) plus keys.mk (PRODUCT_DEFAULT_DEV_CERTIFICATE, PRODUCT_OTA_PUBLIC_KEYS). Use the SAME keys for every update.
- lunaris_flags.mk sets PRODUCT_MAINLINE_BLUETOOTH_SEPOLICY_DEV_CERTIFICATES; without it Bluetooth gets seinfo=default and crashes.
- Never keep .bak files inside overlay res folders (aapt2 fails).
- Build: lunch lineage_malachite-bp4a-user; m bacon
