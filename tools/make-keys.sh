#!/bin/bash
# Creates a complete signing key set for PenguinOS / AOSPA builds of malachite.
#   bash device/xiaomi/malachite/tools/make-keys.sh vendor/aospa-priv/keys \
#     "/C=US/ST=State/L=City/O=YourName/OU=YourName/CN=YourName/emailAddress=you@example.com"
# Run it before the first build (app + AVB keys), then again after the first build: the APEX keys
# are read from that build's own list (META/apexkeys.txt). Existing keys are never overwritten.
# Keep the key folder private and back it up: every future build must use the same keys.
set -u
K=${1:?usage: make-keys.sh <key-dir> "<subject>"}; SUBJ=${2:?subject missing}
mkdir -p "$K"
mk() {
  [ -f "$K/$1.pk8" ] && return 0
  openssl genrsa -f4 -out "/tmp/$1.key" "${2:-2048}" 2>/dev/null \
  && openssl req -new -x509 -sha256 -key "/tmp/$1.key" -out "$K/$1.x509.pem" -days 10000 -subj "$SUBJ" \
  && openssl pkcs8 -in "/tmp/$1.key" -topk8 -outform DER -out "$K/$1.pk8" -nocrypt \
  && rm -f "/tmp/$1.key" && echo "created $1" || { echo "FAILED $1"; return 1; }
}
for k in releasekey platform shared media networkstack bluetooth nfc sdk_sandbox verity cts_uicc_2021 otakey testkey; do mk "$k"; done
[ -f "$K/avb.pem" ] || { openssl genrsa -f4 -out "$K/avb.pem" 4096 2>/dev/null && echo "created avb.pem"; }
[ -f "$K/keys.mk" ] || { echo "PRODUCT_DEFAULT_DEV_CERTIFICATE := $K/releasekey" > "$K/keys.mk"; echo "created keys.mk"; }
TD=$(ls -d out/target/product/malachite/obj/PACKAGING/target_files_intermediates/*-target_files 2>/dev/null | head -1)
if [ -n "$TD" ] && [ -f "$TD/META/apexkeys.txt" ]; then
  for a in $(grep -v 'private_key="PRESIGNED"' "$TD/META/apexkeys.txt" | sed -n 's/.*name="\([^"]*\)".*/\1/p' | sed 's/\.c\{0,1\}apex$//'); do
    mk "$a" 4096 || exit 1
    [ -f "$K/$a.pem" ] || openssl genrsa -f4 -out "$K/$a.pem" 4096 2>/dev/null
    [ -f "$K/$a.avbpubkey" ] || out/host/linux-x86/bin/avbtool extract_public_key --key "$K/$a.pem" --output "$K/$a.avbpubkey"
  done
  echo "APEX keys: $(ls "$K"/com.*.pk8 2>/dev/null | wc -l)"
else
  echo "No target-files yet: build once (unsigned), then run this again to create the APEX keys."
fi
