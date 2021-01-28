pi3-aoe
=======

A basic setup for ATA over Ethernet on a RPi3.


Build steps
-----------

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
