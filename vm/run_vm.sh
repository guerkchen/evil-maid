 sudo qemu-system-x86_64 \
 	-hda ubuntu-desktop-22.04.1.qcow2 \
	-gdb tcp::9000 \
	-k de \
	-smp 1 \
	-m 4G \
	-cdrom ubuntu-22.04.1-desktop-amd64.iso
