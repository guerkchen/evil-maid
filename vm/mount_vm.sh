#/bin/bash

sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 ubuntu-desktop-22.04.1.qcow2
sudo mount -o ro /dev/nbd0p3 ./boot
