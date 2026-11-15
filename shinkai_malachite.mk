#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from device makefile.
$(call inherit-product, device/xiaomi/malachite/device.mk)

# Inherit some common LineageOS stuff.
$(call inherit-product, vendor/custom/config/common_full_phone.mk)

PRODUCT_NAME := shinkai_malachite
PRODUCT_DEVICE := malachite
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
PRODUCT_MODEL := 24090RA29G

PRODUCT_SYSTEM_NAME := malachite_global
PRODUCT_SYSTEM_DEVICE := malachite

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=Xiaomi/hal_mgvi_64_armv82_mt6878_global/mgvi_64_armv82:14/UP1A.231005.007/OS3.0.10.0.WOOMIXM:user/release-keys \
    SystemModel=$(PRODUCT_SYSTEM_DEVICE) \
    SystemName=$(PRODUCT_SYSTEM_NAME) \
    ProductModel=$(PRODUCT_SYSTEM_DEVICE) \
    DeviceProduct=$(PRODUCT_SYSTEM_NAME)

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

# Shinkai
SHINKAI_MAINTAINER := Zoro
WITH_GMS := true

# DEBUG-DEBUGGABLE: keep userdebug debuggable so adb works at boot
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_NOT_DEBUGGABLE_IN_USERDEBUG := false
endif

# The PixelOS-based updater refuses to check without this
PRODUCT_SYSTEM_PROPERTIES += net.pixelos.version=seventeen
PRODUCT_SYSTEM_PROPERTIES += \
    net.pixelos.build_type=UNOFFICIAL \
    ro.custom.version=17
