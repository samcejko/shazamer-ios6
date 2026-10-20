# Shazamer - retro music recognition client for jailbroken iOS. One source tree, two packages (Theos):
#   make package                               armv7 for iOS 5-10 (the iOS 9.3 SDK, deployment target 5.0)
#   make package THEOS_PACKAGE_SCHEME=rootless arm64 for iOS 14-17 (the iOS 16.5 SDK, deployment target 14.0):
#                                              the .deb for rootless jailbreaks, the IPA for TrollStore
# (`make clean` between the two; CI builds both, see .github/workflows/build.yml)

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
TARGET := iphone:clang:16.5:14.0
ARCHS := arm64
else
TARGET := iphone:clang:9.3:5.0
ARCHS := armv7
endif
DEBUG ?= 0

THEOS_DEVICE_IP ?= 192.168.1.166
THEOS_DEVICE_USER ?= root

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := Shazamer

Shazamer_FILES := $(wildcard src/*.m) $(wildcard src/*/*.m) \
                  src/DSP/SZFFT.c \
                  vendor/mbedtls_glue.c \
                  $(wildcard vendor/mbedtls/library/*.c)

Shazamer_FRAMEWORKS := UIKit Foundation CoreGraphics QuartzCore AudioToolbox AVFoundation Security

# Flags for every C-family file (also the vendored mbedTLS sources)
Shazamer_CFLAGS := -Isrc -Isrc/Audio -Isrc/DSP -Isrc/Net -Isrc/Model -Isrc/Theme -Isrc/UI -Isrc/Util \
                   -Ivendor -Ivendor/mbedtls/include -Ivendor/mbedtls/library \
                   -Os -fvisibility=hidden \
                   -Wall -Wno-unused-variable -Wno-unused-function -Wno-unused-but-set-variable \
                   -Wno-deprecated-declarations -Wno-unknown-warning-option \
                   -Wno-nullability-completeness -Wno-nullability-completeness-on-arrays -Wno-error

Shazamer_OBJCFLAGS := -fobjc-arc -Wunguarded-availability -include UIKit/UIKit.h

Shazamer_LDFLAGS := -lz

include $(THEOS)/makefiles/application.mk

SHAZAMER_STAGED_APP := $(THEOS_STAGING_DIR)/Applications/Shazamer.app

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
after-stage::
	python3 "$(THEOS_PROJECT_DIR)/tools/modern_bundle.py" "$(SHAZAMER_STAGED_APP)"
	ldid -S"$(THEOS_PROJECT_DIR)/entitlements-arm64.xml" "$(SHAZAMER_STAGED_APP)/Shazamer"

before-package::
	sed -i -e 's/^Depends: .*/Depends: firmware (>= 15.0)/' "$(THEOS_STAGING_DIR)/DEBIAN/control"
	printf '%s\n' '#!/bin/sh' '[ "$$1" = configure ] || exit 0' \
		'command -v uicache >/dev/null 2>&1 && { uicache -p /var/jb/Applications/Shazamer.app >/dev/null 2>&1 || uicache -a >/dev/null 2>&1; }' \
		'exit 0' > "$(THEOS_STAGING_DIR)/DEBIAN/postinst"
	printf '%s\n' '#!/bin/sh' '[ "$$1" = remove ] || exit 0' \
		'command -v uicache >/dev/null 2>&1 && uicache -a >/dev/null 2>&1' \
		'exit 0' > "$(THEOS_STAGING_DIR)/DEBIAN/postrm"
	chmod 0755 "$(THEOS_STAGING_DIR)/DEBIAN/postinst" "$(THEOS_STAGING_DIR)/DEBIAN/postrm"
endif
