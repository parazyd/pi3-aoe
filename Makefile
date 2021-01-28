.POSIX:

TC="aarch64-linux-gnu-"

KERNEL_URL = https://github.com/raspberrypi/linux
KERNEL_BRANCH = rpi-5.11.y
KERNEL_SRC = linux-raspberrypi
IMAGEGZ = $(KERNEL_SRC)/arch/arm64/boot/Image.gz

FIRMWARE_URL = https://github.com/raspberrypi/firmware
FIRMWARE_BRANCH = master
FIRMWARE_SRC = firmware

AOE_URL = https://github.com/OpenAoE/aoetools
AOE_BRANCH = master
AOE_SRC = aoetools

all: boot/kernel8.img bin/aoe-stat boot/bootcode.bin

$(KERNEL_SRC):
	git clone --depth 1 -b $(KERNEL_BRANCH) $(KERNEL_URL) $@

$(FIRMWARE_SRC):
	git clone --depth 1 -b $(FIRMWARE_BRANCH) $(FIRMWARE_URL) $@

$(AOE_SRC):
	git clone --depth 1 -b $(AOE_BRANCH) $(AOE_URL) $@

boot/bootcode.bin: $(FIRMWARE_SRC)
	mkdir -p boot
	cp $(FIRMWARE_SRC)/boot/start* boot
	cp $(FIRMWARE_SRC)/boot/fixup* boot
	cp $(FIRMWARE_SRC)/boot/LICENCE.broadcom boot
	cp $(FIRMWARE_SRC)/boot/COPYING.linux boot

$(IMAGEGZ): $(KERNEL_SRC)
	cp -f pi3.config $(KERNEL_SRC)/.config
	$(MAKE) -C $(KERNEL_SRC) ARCH=arm64 CROSS_COMPILE=$(TC) oldconfig
	$(MAKE) -C $(KERNEL_SRC) ARCH=arm64 CROSS_COMPILE=$(TC)

boot/kernel8.img: $(IMAGEGZ)
	mkdir -p boot/overlays
	cp $(KERNEL_SRC)/arch/arm64/boot/Image.gz $@
	cp $(KERNEL_SRC)/arch/arm64/boot/dts/broadcom/bcm*.dtb boot
	cp $(KERNEL_SRC)/arch/arm64/boot/dts/overlays/*.dtbo boot/overlays
	cp $(KERNEL_SRC)/arch/arm64/boot/dts/overlays/README boot/overlays

bin/aoe-stat: $(AOE_SRC)
	sed -e 's@^CFLAGS =.*@CFLAGS = -Os -s -static@' -i $(AOE_SRC)/Makefile
	sed -e 's@^SBINDIR =.*@SBINDIR = $${PREFIX}/bin@' -i $(AOE_SRC)/Makefile
	$(MAKE) -C $(AOE_SRC) CC=$(TC)gcc PREFIX=$(CURDIR)
	$(MAKE) -C $(AOE_SRC) CC=$(TC)gcc PREFIX=$(CURDIR) install
	rm -rf usr

.PHONY: all