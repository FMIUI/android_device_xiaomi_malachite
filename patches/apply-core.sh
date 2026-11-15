#!/bin/bash
# Idempotent core fixes the malachite blobs need on Android 17. Re-run on every build.
D=device/xiaomi/malachite/patches
[ -d frameworks/hardware/interfaces/displayservice ] || tar -C frameworks/hardware/interfaces -xzf $D/displayservice.tar.gz
H=system/tools/hidl/build/hidl_interface.go
if [ -f "$H" ] && ! grep -q '"android.frameworks.displayservice@1.0"' "$H"; then
python3 - "$H" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
anchor = """	"android.frameworks.sensorservice@1.0":         true,"""; line = """	"android.frameworks.displayservice@1.0":         true,"""
i = s.find(anchor)
if i < 0: sys.exit("malachite: hidl allowlist anchor not found")
j = s.index("\n", i) + 1
open(p, "w").write(s[:j] + line + "\n" + s[j:])
PY
fi
# Android 17 forbids native_app_zygote from finding vendor services, but MediaTek's Mali rule grants it to all domains.
Z=system/sepolicy/private/native_app_zygote.te
if [ -f "$Z" ] && ! grep -q "malachite: mali" "$Z"; then
python3 - "$Z" <<'PY2'
import sys
p = sys.argv[1]; s = open(p).read()
old = "  -webviewupdate_service\n}:service_manager find;"
new = "  -webviewupdate_service\n  -hal_service_type  # malachite: mali\n}:service_manager find;"
if old not in s: sys.exit("malachite: native_app_zygote neverallow not found")
open(p, "w").write(s.replace(old, new, 1))
PY2
fi
exit 0
