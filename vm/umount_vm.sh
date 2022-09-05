#!/bin/bash

sudo umount /dev/nbd0p3
sudo qemu-nbd -d /dev/nbd0
