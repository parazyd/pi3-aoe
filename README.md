pi3-aoe
=======

A basic setup for ATA over Ethernet on a RPi3.


Quick, and maybe dangerous
--------------------------

Edit `boot/cmdline.txt` to match your AoE shelf.

```
( echo -e '#!/bin/sh\nset -e\n' ; grep '^;' README.md | sed 's/^; //' ) > install.sh
sh install.sh
```

Build steps
-----------

* Edit `boot/cmdline.txt` to match your AoE shelf.

* Run `make -j32` to build everything

```
; make -j32
```

* Create an image to dd on a microsd:

```
; dd if=/dev/zero of=pi3aoe.img bs=1M count=100
; loopdevice="$(sudo losetup -f --show pi3aoe.img)"
; sudo parted "$loopdevice" --script -- mklabel msdos
; sudo parted "$loopdevice" --script -- mkpart primary "fat32 2048s 70MB"
; sudo parted "$loopdevice" --script -- mkpart primary "ext4 70MB 100%"
; sudo mkfs.vfat "${loopdevice}p1"
; sudo mkfs.ext4 "${loopdevice}p2"
; mkdir -p mnt
; sudo mount "${loopdevice}p2" mnt
; sudo mkdir -p mnt/boot
; sudo mount "${loopdevice}p1" mnt/boot
```

* Install

```
; sudo make DESTDIR="$PWD/mnt" install
```

* Unmount and remove

```
; sudo umount -R mnt
; sudo partx -dv "$loopdevice"
; sudo losetup -d "$loopdevice"
```

Now you're ready to dd.


Example AoE image setup
-----------------------

```
dd if=/dev/zero bs=1MiB count=0 seek=100000 of=aoe-pi3-arm64.img
mkfs.ext4 aoe-pi3-arm64.img
mkdir mnt
mount -o loop aoe-pi3-arm64.img mnt
debootstrap --arch=arm64 --foreign beowulf mnt https://pkgmaster.devuan.org/merged
cp -a /usr/bin/qemu-aarch64 mnt/usr/bin
[ -d /proc/sys/fs/binfmt_misc ] || modprobe binfmt_misc
[ -f /proc/sys/fs/binfmt_misc/register ] || mount binfmt_bisc -t binfmt_misc /proc/sys/fs/binfmt_misc
/etc/init.d/qemu-binfmt start || /etc/init.d/binfmt-support start
chroot mnt /debootstrap/debootstrap --second-stage
rm -f mnt/usr/bin/qemu-aarch64
```