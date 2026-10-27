# LineageOS 24.0 for the Redmi Note 14 Pro 5G / POCO X7 5G (malachite)

Device tree for an unofficial LineageOS 24.0 (Android 17) build for malachite.

**Downloads, updates and support:** [Telegram group](https://t.me/malachite_project)

## Branch

`lineage-24.0` is the current branch, in this repository and in every other
[malachite-project](https://github.com/malachite-project) fork. To base work on
these trees, use `lineage-24.0`. `lineage-23.2` (Android 16) stays as it was;
[bringup/LINEAGE-24.md](bringup/LINEAGE-24.md) lists what moving each fork to
24.0 changed.

## Building

`manifests/malachite.xml` is the local manifest for the whole tree: set up a
LineageOS 24.0 checkout, copy it to `.repo/local_manifests/`, sync, then
`breakfast malachite`. The comment at its top lists what each fork changes.
Kernel sources are built separately; see
[kernel_manifest-6.1](https://github.com/malachite-project/kernel_manifest-6.1).

## Source ID

Every build made from these trees, whatever the ROM and whether it uses these
repositories or forks of them, records where its device, vendor and kernel trees came
from:

```
adb shell getprop | grep malachite.source
[ro.malachite.source.device]: [malachite-project/android_device_xiaomi_malachite@a917ca0]
[ro.malachite.source.kernel]: [malachite-project/android_device_xiaomi_malachite-kernel@a9522e4]
[ro.malachite.source.vendor]: [malachite-project/android_vendor_xiaomi_malachite@7e73953]
```

Each value is the repository the tree was synced from (or pushed to) and the commit
that was built. Nothing has to be done to get it; for a build anyone can trace:

- keep the trees as git checkouts (repo sync or git clone, not copies);
- commit your changes and push them before building. `-dirty` means the tree had
  uncommitted changes, `-unpublished` that the commit was on no remote branch, and
  then nobody else can get that exact source.

Put the three lines in your release notes and in bug reports.

## Credits

Built on the work of [mt6878-devs](https://github.com/mt6878-devs),
[puhboo](https://github.com/puhboo) and [cmdr-chara](https://github.com/cmdr-chara),
and of the LineageOS project.

```
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#
```
