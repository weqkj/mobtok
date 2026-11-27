TARGET := iphone:clang:latest:15.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = TikTok

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = mobtok
mobtok_FILES = $(wildcard src/*.x) $(wildcard src/*.m)
mobtok_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
mobtok_FRAMEWORKS = UIKit CoreText CoreGraphics Photos CoreTelephony QuartzCore LocalAuthentication
mobtok_LOGOS_DEFAULT_GENERATOR = internal   # без Substrate: работает при инъекции в IPA

include $(THEOS_MAKE_PATH)/tweak.mk
