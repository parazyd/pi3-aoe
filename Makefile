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

BUSYBOX_URL = https://git.busybox.net/busybox
BUSYBOX_BRANCH = 1_32_1
BUSYBOX_SRC = busybox

all: boot/kernel8.img bin/aoe-stat boot/bootcode.bin bin/busybox

$(KERNEL_SRC):
	git clone --depth 1 -b $(KERNEL_BRANCH) $(KERNEL_URL) $@

$(FIRMWARE_SRC):
	git clone --depth 1 -b $(FIRMWARE_BRANCH) $(FIRMWARE_URL) $@

$(AOE_SRC):
	git clone --depth 1 -b $(AOE_BRANCH) $(AOE_URL) $@

$(BUSYBOX_SRC):
	git clone --depth 1 -b $(BUSYBOX_BRANCH) $(BUSYBOX_URL) $@

boot/bootcode.bin: $(FIRMWARE_SRC)
	cp $(FIRMWARE_SRC)/boot/start* boot
	cp $(FIRMWARE_SRC)/boot/fixup* boot
	cp $(FIRMWARE_SRC)/boot/LICENCE.broadcom boot
	cp $(FIRMWARE_SRC)/boot/COPYING.linux boot
	cp $(FIRMWARE_SRC)/boot/bootcode.bin boot

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

bin/busybox: $(BUSYBOX_SRC)
	cp busybox.config $(BUSYBOX_SRC)/.config
	$(MAKE) -C $(BUSYBOX_SRC) ARCH=arm64 CROSS_COMPILE=$(TC) busybox
	cp $(BUSYBOX_SRC)/busybox $@

install: all
ifeq ($(DESTDIR),)
	@echo "You need to set DESTDIR. See README.md for more information."
	exit 1
endif
	mkdir -p $(DESTDIR)/dev $(DESTDIR)/proc $(DESTDIR)/sys
	cp -r boot/* $(DESTDIR)/boot
	cp -r bin $(DESTDIR)/bin
	cp init $(DESTDIR)/init
	chmod 755 $(DESTDIR)/init

.PHONY: all install
