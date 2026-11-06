# Lunaris flags
TARGET_CUSTOM_UDFPS := true
WITH_GMS := true
WITH_GMS_COMMS_SUITE := false
WITH_PIXEL_LAUNCHER := false
TARGET_USE_MAPS := true
TARGET_USE_FILES := false
TARGET_USE_GPHOTOS := true
TARGET_USE_WALLPAPERS := true
USE_REALITY_ENGINE := false
SURFACE_FLINGER_BOOST := true

$(call soong_config_set,surfaceflinger,frame_rate_category_high,120)
$(call soong_config_set,surfaceflinger,frame_rate_category_min,60)

PRODUCT_SYSTEM_PROPERTIES += ro.lunaris.maintainer=Zoro
