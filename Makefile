# Makefile
THEOS_PACKAGE_SCHEME = rootless

ARCHS = arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FakeLocationTest
FakeLocationTest_FILES = Tweak.x
FakeLocationTest_FRAMEWORKS = UIKit CoreLocation

FakeLocationTest_LDFLAGS = -dynamiclib -Wl,-ld_classic -Wl,-no_warn_duplicate_libraries

include $(THEOS_MAKE_PATH)/tweak.mk
